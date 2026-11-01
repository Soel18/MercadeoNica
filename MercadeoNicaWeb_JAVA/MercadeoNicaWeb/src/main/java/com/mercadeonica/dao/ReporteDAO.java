package com.mercadeonica.dao;

import com.mercadeonica.conexion.ConexionBD;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ReporteDAO {

    public List<Map<String, Object>> reporteInventario() {
        List<Map<String, Object>> lista = new ArrayList<>();

        String sql = "SELECT pc.categoryname AS categoria, " +
                     "COUNT(p.productid) AS cantidad, " +
                     "ISNULL(SUM(p.availablequantity), 0) AS stock, " +
                     "ISNULL(SUM(p.availablequantity * p.unitprice), 0) AS valor " +
                     "FROM ProductCategories pc " +
                     "LEFT JOIN products p ON pc.categoryid = p.categoryid " +
                     "GROUP BY pc.categoryname";

        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> fila = new HashMap<>();
                fila.put("categoria", rs.getString("categoria"));
                fila.put("cantidad", rs.getInt("cantidad"));
                fila.put("stock", rs.getInt("stock"));
                fila.put("valor", rs.getDouble("valor"));
                lista.add(fila);
            }
        } catch (SQLException e) {
            System.err.println("❌ Error en reporte inventario: " + e.getMessage());
        }
        return lista;
    }

    public List<Map<String, Object>> reporteMejoresClientes(double minimo) {
        List<Map<String, Object>> lista = new ArrayList<>();

        String sql = "SELECT c.name AS cliente, SUM(od.subtotal) AS total " +
                     "FROM order_details od " +
                     "INNER JOIN orders o ON o.orderid = od.orderid " +
                     "INNER JOIN customers c ON c.customerid = o.customerid " +
                     "GROUP BY c.name " +
                     "HAVING SUM(od.subtotal) > ? " +
                     "ORDER BY SUM(od.subtotal) DESC";

        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setDouble(1, minimo);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> fila = new HashMap<>();
                    fila.put("cliente", rs.getString("cliente"));
                    fila.put("total", rs.getDouble("total"));
                    lista.add(fila);
                }
            }
        } catch (SQLException e) {
            System.err.println("❌ Error en reporte mejores clientes: " + e.getMessage());
        }
        return lista;
    }

    // 🔥 CORREGIDO: Solo vendedores con ventas > 0 y ordenados
    public List<Map<String, Object>> reporteVentasPorVendedor() {
        List<Map<String, Object>> lista = new ArrayList<>();

        String sql = "SELECT s.name AS vendedor, s.role AS rol, " +
                     "COUNT(DISTINCT o.orderid) AS pedidos, " +
                     "ISNULL(SUM(od.subtotal), 0) AS total " +
                     "FROM sellers s " +
                     "INNER JOIN orders o ON o.sellerid = s.sellerid " + // 🔥 INNER JOIN
                     "INNER JOIN order_details od ON od.orderid = o.orderid " +
                     "WHERE o.status != 'CANCELADO' " + // 🔥 Excluir cancelados
                     "GROUP BY s.name, s.role " +
                     "HAVING ISNULL(SUM(od.subtotal), 0) > 0 " + // 🔥 Solo > 0
                     "ORDER BY ISNULL(SUM(od.subtotal), 0) DESC";

        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> fila = new HashMap<>();
                fila.put("vendedor", rs.getString("vendedor"));
                fila.put("rol", rs.getString("rol"));
                fila.put("pedidos", rs.getInt("pedidos"));
                fila.put("total", rs.getDouble("total"));
                lista.add(fila);
            }
        } catch (SQLException e) {
            System.err.println("❌ Error en reporte ventas por vendedor: " + e.getMessage());
        }
        return lista;
    }

    public List<Map<String, Object>> reporteMovimientosInventario() {
        List<Map<String, Object>> lista = new ArrayList<>();

        String sql = "SELECT TOP 20 m.movementid, p.productname, " +
                     "m.movement_type, m.quantity, m.reason, m.movement_date " +
                     "FROM inventory_movements m " +
                     "INNER JOIN products p ON m.productid = p.productid " +
                     "ORDER BY m.movement_date DESC";

        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> fila = new HashMap<>();
                fila.put("id", rs.getInt("movementid"));
                fila.put("producto", rs.getString("productname"));
                fila.put("tipo", rs.getString("movement_type"));
                fila.put("cantidad", rs.getInt("quantity"));
                fila.put("motivo", rs.getString("reason"));
                fila.put("fecha", rs.getTimestamp("movement_date"));
                lista.add(fila);
            }
        } catch (SQLException e) {
            System.err.println("❌ Error en reporte movimientos: " + e.getMessage());
        }
        return lista;
    }

    public List<Map<String, Object>> reporteResenas() {
        List<Map<String, Object>> lista = new ArrayList<>();

        String sql = "SELECT p.productname AS producto, " +
                     "AVG(CAST(r.starsgiven AS DECIMAL(10,2))) AS promedio, " +
                     "COUNT(r.reviewID) AS total_resenas " +
                     "FROM products p " +
                     "INNER JOIN reviews r ON r.productID = p.productid " +
                     "GROUP BY p.productname " +
                     "ORDER BY AVG(CAST(r.starsgiven AS DECIMAL(10,2))) DESC";

        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> fila = new HashMap<>();
                fila.put("producto", rs.getString("producto"));
                fila.put("promedio", rs.getDouble("promedio"));
                fila.put("total", rs.getInt("total_resenas"));
                lista.add(fila);
            }
        } catch (SQLException e) {
            System.err.println("❌ Error en reporte reseñas: " + e.getMessage());
        }
        return lista;
    }

    public Map<String, Object> estadisticasGenerales() {
        Map<String, Object> stats = new HashMap<>();

        try (Connection cn = ConexionBD.getConexion()) {

            try (Statement st = cn.createStatement();
                 ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM customers WHERE active = 1")) {
                if (rs.next()) stats.put("totalClientes", rs.getInt(1));
            }

            try (Statement st = cn.createStatement();
                 ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM products")) {
                if (rs.next()) stats.put("totalProductos", rs.getInt(1));
            }

            try (Statement st = cn.createStatement();
                 ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM orders")) {
                if (rs.next()) stats.put("totalPedidos", rs.getInt(1));
            }

            try (Statement st = cn.createStatement();
                 ResultSet rs = st.executeQuery("SELECT ISNULL(SUM(total), 0) FROM orders WHERE status != 'CANCELADO'")) {
                if (rs.next()) stats.put("totalFacturado", rs.getDouble(1));
            }

            try (Statement st = cn.createStatement();
                 ResultSet rs = st.executeQuery("SELECT ISNULL(SUM(availablequantity), 0) FROM products")) {
                if (rs.next()) stats.put("totalStock", rs.getInt(1));
            }

        } catch (SQLException e) {
            System.err.println("❌ Error en estadísticas: " + e.getMessage());
        }
        return stats;
    }
}