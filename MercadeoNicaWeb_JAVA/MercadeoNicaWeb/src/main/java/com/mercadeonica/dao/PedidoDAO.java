package com.mercadeonica.dao;

import com.mercadeonica.conexion.ConexionBD;
import com.mercadeonica.modelo.DetallePedido;
import com.mercadeonica.modelo.Pedido;
import com.mercadeonica.modelo.Producto;

import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;

public class PedidoDAO {

    public String verificarStock(List<DetallePedido> detalles) {
        if (detalles == null || detalles.isEmpty()) return "El pedido no tiene productos.";
        String sql = "SELECT productname, availablequantity FROM products WHERE productid = ?";
        try (Connection cn = ConexionBD.getConexion(); PreparedStatement ps = cn.prepareStatement(sql)) {
            for (DetallePedido d : detalles) {
                ps.setInt(1, d.getProducto().getProductId());
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String nombre = rs.getString("productname");
                        int disponible = rs.getInt("availablequantity");
                        int solicitado = d.getCantidad();
                        if (disponible < solicitado) {
                            return "Stock insuficiente de '" + nombre + "'. Disponible: " + disponible + ", solicitado: " + solicitado + ".";
                        }
                    } else {
                        return "Producto con ID " + d.getProducto().getProductId() + " no existe.";
                    }
                }
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al verificar stock: " + e.getMessage());
            return "Error al verificar el stock: " + e.getMessage();
        }
        return null;
    }

    private boolean descontarStock(Connection cn, int productId, int cantidad, int orderId) throws SQLException {
        String sql = "UPDATE products SET availablequantity = availablequantity - ? " +
                     "WHERE productid = ? AND availablequantity >= ?";
        try (PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, cantidad);
            ps.setInt(2, productId);
            ps.setInt(3, cantidad);
            int filas = ps.executeUpdate();
            if (filas > 0) {
                System.out.println("   📦 Stock descontado: producto " + productId + " (-" + cantidad + ")");
                
                String sqlMov = "INSERT INTO inventory_movements (productid, movement_type, quantity, reason) " +
                                "VALUES (?, 'SALIDA', ?, ?)";
                try (PreparedStatement psMov = cn.prepareStatement(sqlMov)) {
                    psMov.setInt(1, productId);
                    psMov.setInt(2, -cantidad);
                    psMov.setString(3, "Venta (detalle del pedido " + orderId + ")");
                    psMov.executeUpdate();
                    System.out.println("   📝 Movimiento de inventario registrado para producto " + productId);
                }
                return true;
            } else {
                System.err.println("   ❌ No se pudo descontar stock del producto " + productId);
                return false;
            }
        }
    }

    public boolean registrar(Pedido pedido) {
        return registrarConDescuento(pedido, 0);
    }

    public boolean registrarConDescuento(Pedido pedido, double descuentoPorcentaje) {
        System.out.println("🔵 PedidoDAO.registrarConDescuento - Descuento: " + descuentoPorcentaje + "%");

        String errorStock = verificarStock(pedido.getDetalles());
        if (errorStock != null) {
            System.err.println("❌ " + errorStock);
            return false;
        }

        Connection cn = null;
        try {
            cn = ConexionBD.getConexion();
            cn.setAutoCommit(false);

            StringBuilder items = new StringBuilder("[");
            for (int i = 0; i < pedido.getDetalles().size(); i++) {
                DetallePedido d = pedido.getDetalles().get(i);
                items.append("{\"productid\":").append(d.getProducto().getProductId())
                     .append(",\"quantity\":").append(d.getCantidad()).append("}");
                if (i < pedido.getDetalles().size() - 1) items.append(",");
            }
            items.append("]");

            String json = items.toString();
            System.out.println("   JSON items: " + json);

            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            Timestamp fechaSQL = Timestamp.valueOf(sdf.format(pedido.getFecha()));

            String estado = pedido.getEstado() != null ? pedido.getEstado() : "PENDIENTE";

            int pedidosAntes = contarPedidos(cn);
            System.out.println("   📊 Pedidos antes del INSERT: " + pedidosAntes);

            int sellerIdCorrecto = pedido.getSellerId();
            System.out.println("   🧑‍💼 SellerID que se guardará: " + sellerIdCorrecto);

            String sql = "{call place_order_full(?, ?, ?, ?, ?, ?, ?)}";
            try (CallableStatement cs = cn.prepareCall(sql)) {
                cs.setInt(1, pedido.getCustomerId());
                cs.setInt(2, sellerIdCorrecto);
                cs.setTimestamp(3, fechaSQL);
                cs.setLong(4, pedido.getCcNumber());
                cs.setString(5, json);
                cs.setDouble(6, pedido.calcularTotal());
                cs.setString(7, estado);
                cs.execute();
            }

            int pedidosDespues = contarPedidos(cn);
            System.out.println("   📊 Pedidos después del INSERT: " + pedidosDespues);

            if (pedidosDespues <= pedidosAntes) {
                throw new SQLException("El pedido NO se guardó en la BD. El SP hizo ROLLBACK.");
            }

            System.out.println("   ✅ Pedido insertado en 'orders' (verificado)");

            int nuevoOrderId = obtenerUltimoOrderId(cn);

            if (sellerIdCorrecto > 0) {
                String sqlUpdateSeller = "UPDATE orders SET sellerid = ? WHERE orderid = ?";
                try (PreparedStatement ps = cn.prepareStatement(sqlUpdateSeller)) {
                    ps.setInt(1, sellerIdCorrecto);
                    ps.setInt(2, nuevoOrderId);
                    ps.executeUpdate();
                    System.out.println("   🔄 SellerID forzado a " + sellerIdCorrecto);
                }
            } else {
                System.out.println("   ℹ️ SellerID = 0 (venta de cliente), no se fuerza el vendedor. Se asigna al Admin por defecto.");
            }

            for (DetallePedido d : pedido.getDetalles()) {
                boolean ok = descontarStock(cn, d.getProducto().getProductId(), d.getCantidad(), nuevoOrderId);
                if (!ok) {
                    System.err.println("❌ Error al descontar stock. Haciendo ROLLBACK...");
                    cn.rollback();
                    return false;
                }
            }

            cn.commit();
            System.out.println("✅ Pedido registrado y stock descontado correctamente.");
            return true;

        } catch (SQLException e) {
            System.err.println("❌ Error SQL: " + e.getMessage());
            e.printStackTrace();
            if (cn != null) {
                try {
                    cn.rollback();
                    System.out.println("   🔄 Transacción revertida (ROLLBACK)");
                } catch (SQLException ex) {
                    System.err.println("   ❌ Error al hacer rollback: " + ex.getMessage());
                }
            }
            return false;
        } finally {
            if (cn != null) {
                try {
                    cn.setAutoCommit(true);
                    cn.close();
                } catch (SQLException ex) {
                    System.err.println("   ❌ Error al cerrar conexión: " + ex.getMessage());
                }
            }
        }
    }

    private int contarPedidos(Connection cn) throws SQLException {
        String sql = "SELECT COUNT(*) FROM orders";
        try (PreparedStatement ps = cn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        }
        return 0;
    }

    private int obtenerUltimoOrderId(Connection cn) throws SQLException {
        String sql = "SELECT MAX(orderid) FROM orders";
        try (PreparedStatement ps = cn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        }
        return 0;
    }

    public List<Pedido> listarPedidos() { return listarPedidos(null); }

    // 🔥 MODIFICADO: incluye c.state
    public List<Pedido> listarPedidos(String estadoFiltro) {
        List<Pedido> lista = new ArrayList<>();
        String sql = "SELECT o.orderid, o.customerid, o.sellerid, o.orderdate, " +
                     "o.cc_number, o.status, o.total, " +
                     "c.name  AS customer_name, c.email AS customer_email, c.state AS cliente_pais, " +
                     "s.name AS seller_name " +
                     "FROM orders o " +
                     "LEFT JOIN customers c ON o.customerid = c.customerid " +
                     "LEFT JOIN sellers   s ON o.sellerid   = s.sellerid ";

        if (estadoFiltro != null && !estadoFiltro.isEmpty()) {
            sql += "WHERE o.status = ? ";
        }
        sql += "ORDER BY o.orderid DESC";

        try (Connection cn = ConexionBD.getConexion(); PreparedStatement ps = cn.prepareStatement(sql)) {
            
            if (estadoFiltro != null && !estadoFiltro.isEmpty()) {
                ps.setString(1, estadoFiltro);
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Pedido p = new Pedido();
                    p.setOrderId(rs.getInt("orderid"));
                    p.setCustomerId(rs.getInt("customerid"));
                    p.setSellerId(rs.getInt("sellerid"));
                    p.setFecha(rs.getDate("orderdate"));
                    p.setCcNumber(rs.getLong("cc_number"));
                    p.setEstado(rs.getString("status"));
                    p.setTotal(rs.getDouble("total"));
                    p.setCustomerName(rs.getString("customer_name"));
                    p.setCustomerEmail(rs.getString("customer_email"));
                    p.setClientePais(rs.getString("cliente_pais")); // 🔥
                    p.setSellerName(rs.getString("seller_name"));
                    lista.add(p);
                }
            }
            System.out.println("✅ Pedidos encontrados: " + lista.size() + (estadoFiltro != null ? " (filtro: " + estadoFiltro + ")" : ""));
        } catch (SQLException e) {
            System.err.println("❌ Error al listar pedidos: " + e.getMessage());
        }
        return lista;
    }

    // 🔥 MODIFICADO: incluye c.state
    public List<Pedido> listarPedidosDeCliente(int customerId, String estadoFiltro) {
        List<Pedido> lista = new ArrayList<>();
        String sql = "SELECT o.orderid, o.customerid, o.sellerid, o.orderdate, " +
                     "o.cc_number, o.status, o.total, " +
                     "c.name  AS customer_name, c.email AS customer_email, c.state AS cliente_pais, " +
                     "s.name AS seller_name " +
                     "FROM orders o " +
                     "LEFT JOIN customers c ON o.customerid = c.customerid " +
                     "LEFT JOIN sellers   s ON o.sellerid   = s.sellerid " +
                     "WHERE o.customerid = ? ";
        if (estadoFiltro != null && !estadoFiltro.isEmpty()) sql += "AND o.status = ? ";
        sql += "ORDER BY o.orderid DESC";
        try (Connection cn = ConexionBD.getConexion(); PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, customerId);
            if (estadoFiltro != null && !estadoFiltro.isEmpty()) ps.setString(2, estadoFiltro);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Pedido p = new Pedido();
                    p.setOrderId(rs.getInt("orderid"));
                    p.setCustomerId(rs.getInt("customerid"));
                    p.setSellerId(rs.getInt("sellerid"));
                    p.setFecha(rs.getDate("orderdate"));
                    p.setCcNumber(rs.getLong("cc_number"));
                    p.setEstado(rs.getString("status"));
                    p.setTotal(rs.getDouble("total"));
                    p.setCustomerName(rs.getString("customer_name"));
                    p.setCustomerEmail(rs.getString("customer_email"));
                    p.setClientePais(rs.getString("cliente_pais")); // 🔥
                    p.setSellerName(rs.getString("seller_name"));
                    lista.add(p);
                }
            }
            System.out.println("✅ Pedidos del cliente " + customerId + ": " + lista.size());
        } catch (SQLException e) {
            System.err.println("❌ Error al listar pedidos del cliente: " + e.getMessage());
        }
        return lista;
    }

    public List<DetallePedido> listarDetalles(int orderId) {
        List<DetallePedido> lista = new ArrayList<>();
        String sql = "SELECT od.detailid, od.orderid, od.productid, od.quantity, od.unitprice, od.subtotal, p.productname " +
                     "FROM order_details od " +
                     "LEFT JOIN products p ON od.productid = p.productid " +
                     "WHERE od.orderid = ? ORDER BY od.detailid";
        try (Connection cn = ConexionBD.getConexion(); PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    DetallePedido d = new DetallePedido();
                    Producto prod = new Producto();
                    prod.setProductId(rs.getInt("productid"));
                    prod.setNombre(rs.getString("productname"));
                    prod.setPrecioUnitario(rs.getDouble("unitprice"));
                    d.setDetailId(rs.getInt("detailid"));
                    d.setOrderId(rs.getInt("orderid"));
                    d.setProducto(prod);
                    d.setCantidad(rs.getInt("quantity"));
                    d.setPrecioUnitario(rs.getDouble("unitprice"));
                    lista.add(d);
                }
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al listar detalles: " + e.getMessage());
        }
        return lista;
    }

    public boolean cambiarEstado(int orderId, String nuevoEstado) {
        String sql = "UPDATE orders SET status = ? WHERE orderid = ?";
        try (Connection cn = ConexionBD.getConexion(); PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, nuevoEstado);
            ps.setInt(2, orderId);
            int filas = ps.executeUpdate();
            if (filas > 0) {
                System.out.println("✅ Pedido #" + orderId + " cambiado a: " + nuevoEstado);
                return true;
            }
            return false;
        } catch (SQLException e) {
            System.err.println("❌ Error al cambiar estado: " + e.getMessage());
            return false;
        }
    }

    public String cancelarPedidoConDevolucion(int orderId, int customerId) {
        Connection cn = null;
        try {
            cn = ConexionBD.getConexion();
            cn.setAutoCommit(false);

            String sqlCheck = "SELECT status FROM orders WHERE orderid = ? AND customerid = ?";
            String estadoActual = null;
            try (PreparedStatement ps = cn.prepareStatement(sqlCheck)) {
                ps.setInt(1, orderId);
                ps.setInt(2, customerId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) estadoActual = rs.getString("status");
                }
            }
            if (estadoActual == null) { cn.rollback(); return "No se encontró el pedido o no te pertenece."; }
            if (!"PENDIENTE".equals(estadoActual)) { cn.rollback(); return "Solo se pueden cancelar pedidos en estado PENDIENTE. Este está: " + estadoActual + "."; }

            List<DetallePedido> detalles = listarDetalles(orderId);
            String sqlDevolver = "UPDATE products SET availablequantity = availablequantity + ? WHERE productid = ?";
            try (PreparedStatement ps = cn.prepareStatement(sqlDevolver)) {
                for (DetallePedido d : detalles) {
                    ps.setInt(1, d.getCantidad());
                    ps.setInt(2, d.getProducto().getProductId());
                    ps.executeUpdate();
                }
            }
            String sqlMov = "INSERT INTO inventory_movements (productid, movement_type, quantity, reason) VALUES (?, 'DEVOLUCION', ?, ?)";
            try (PreparedStatement ps = cn.prepareStatement(sqlMov)) {
                for (DetallePedido d : detalles) {
                    ps.setInt(1, d.getProducto().getProductId());
                    ps.setInt(2, d.getCantidad());
                    ps.setString(3, "Cancelación del pedido #" + orderId + " por el cliente");
                    ps.executeUpdate();
                }
            }
            String sqlUpdate = "UPDATE orders SET status = 'CANCELADO' WHERE orderid = ?";
            try (PreparedStatement ps = cn.prepareStatement(sqlUpdate)) {
                ps.setInt(1, orderId);
                ps.executeUpdate();
            }
            cn.commit();
            return null;
        } catch (SQLException e) {
            if (cn != null) try { cn.rollback(); } catch (SQLException ex) {}
            return "Error de BD: " + e.getMessage();
        } finally {
            if (cn != null) try { cn.setAutoCommit(true); cn.close(); } catch (SQLException ex) {}
        }
    }

    public java.util.Map<String, Object> obtenerFactura(int orderId) {
        String sql = "SELECT i.invoiceid, i.amount, i.creditcard, cc.creditcard_type " +
                     "FROM invoices i LEFT JOIN creditcards cc ON i.creditcard = cc.creditcard " +
                     "WHERE i.orderid = ?";
        try (Connection cn = ConexionBD.getConexion(); PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    java.util.Map<String, Object> f = new java.util.HashMap<>();
                    f.put("invoiceid", rs.getInt("invoiceid"));
                    f.put("amount", rs.getDouble("amount"));
                    f.put("creditcard", rs.getLong("creditcard"));
                    f.put("creditcard_type", rs.getString("creditcard_type"));
                    return f;
                }
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al obtener factura: " + e.getMessage());
        }
        return null;
    }

    // 🔥 MODIFICADO: incluye c.state
    public Pedido buscarPorId(int orderId) {
        String sql = "SELECT o.orderid, o.customerid, o.sellerid, o.orderdate, o.cc_number, o.status, o.total, " +
                     "c.name AS customer_name, c.email AS customer_email, c.state AS cliente_pais, " +
                     "s.name AS seller_name " +
                     "FROM orders o " +
                     "LEFT JOIN customers c ON o.customerid = c.customerid " +
                     "LEFT JOIN sellers   s ON o.sellerid   = s.sellerid " +
                     "WHERE o.orderid = ?";
        try (Connection cn = ConexionBD.getConexion(); PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Pedido p = new Pedido();
                    p.setOrderId(rs.getInt("orderid"));
                    p.setCustomerId(rs.getInt("customerid"));
                    p.setSellerId(rs.getInt("sellerid"));
                    p.setFecha(rs.getDate("orderdate"));
                    p.setCcNumber(rs.getLong("cc_number"));
                    p.setEstado(rs.getString("status"));
                    p.setTotal(rs.getDouble("total"));
                    p.setCustomerName(rs.getString("customer_name"));
                    p.setCustomerEmail(rs.getString("customer_email"));
                    p.setClientePais(rs.getString("cliente_pais")); // 🔥
                    p.setSellerName(rs.getString("seller_name"));
                    return p;
                }
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al buscar pedido: " + e.getMessage());
        }
        return null;
    }
}