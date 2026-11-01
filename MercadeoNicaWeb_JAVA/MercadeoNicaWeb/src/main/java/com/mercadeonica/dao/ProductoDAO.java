package com.mercadeonica.dao;

import com.mercadeonica.conexion.ConexionBD;
import com.mercadeonica.modelo.Producto;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ProductoDAO {

    private static final String SELECT_BASE =
        "SELECT p.productid, p.productname, p.availablequantity, " +
        "p.unitprice, p.categoryid, c.categoryname, " +
        "ISNULL((SELECT AVG(CAST(r.starsgiven AS DECIMAL(10,2))) " +
        "        FROM reviews r WHERE r.productid = p.productid), 0) AS promedio " +
        "FROM products p " +
        "LEFT JOIN ProductCategories c ON p.categoryid = c.categoryid ";

    private Producto mapear(ResultSet rs) throws SQLException {
        Producto p = new Producto(
                rs.getInt("productid"),
                rs.getString("productname"),
                rs.getInt("availablequantity"),
                rs.getDouble("unitprice"),
                rs.getInt("categoryid"));
        p.setCategoriaNombre(rs.getString("categoryname"));
        return p;
    }

    public List<Producto> listar() {
        List<Producto> lista = new ArrayList<>();
        String sql = SELECT_BASE + "ORDER BY p.productid";

        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapear(rs));
        } catch (SQLException e) {
            System.err.println("❌ Error al listar productos: " + e.getMessage());
        }
        return lista;
    }

    public List<Producto> buscarConFiltros(String q, Integer categoriaId,
                                            Double precioMin, Double precioMax,
                                            boolean soloDisponibles, String orden,
                                            String filtroResenas) {

        List<Producto> lista = new ArrayList<>();
        StringBuilder sql = new StringBuilder(SELECT_BASE);
        List<Object> params = new ArrayList<>();

        sql.append("WHERE 1=1 ");

        if (q != null && !q.trim().isEmpty()) {
            sql.append("AND p.productname LIKE ? ");
            params.add("%" + q.trim() + "%");
        }

        if (categoriaId != null && categoriaId > 0) {
            sql.append("AND p.categoryid = ? ");
            params.add(categoriaId);
        }

        if (precioMin != null) {
            sql.append("AND p.unitprice >= ? ");
            params.add(precioMin);
        }

        if (precioMax != null) {
            sql.append("AND p.unitprice <= ? ");
            params.add(precioMax);
        }

        if (soloDisponibles) {
            sql.append("AND p.availablequantity > 0 ");
        }

        if (filtroResenas != null && !"todas".equals(filtroResenas)) {
            if ("sin".equals(filtroResenas)) {
                sql.append("AND NOT EXISTS (SELECT 1 FROM reviews r WHERE r.productid = p.productid) ");
            } else {
                try {
                    int minStars = Integer.parseInt(filtroResenas);
                    sql.append("AND ISNULL((SELECT AVG(CAST(r.starsgiven AS DECIMAL(10,2))) " +
                               "FROM reviews r WHERE r.productid = p.productid), 0) >= ? ");
                    params.add((double) minStars);
                } catch (NumberFormatException ignored) {}
            }
        }

        String orderBy;
        if ("nombre".equals(orden))                     orderBy = "p.productname ASC";
        else if ("precio_asc".equals(orden))            orderBy = "p.unitprice ASC";
        else if ("precio_desc".equals(orden))           orderBy = "p.unitprice DESC";
        else if ("mejor_calificado".equals(orden))      orderBy = "promedio DESC, p.productid DESC";
        else if ("peor_calificado".equals(orden))       orderBy = "promedio ASC, p.productid DESC";
        else                                            orderBy = "p.productid DESC";
        sql.append("ORDER BY ").append(orderBy);

        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql.toString())) {

            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapear(rs));
            }
        } catch (SQLException e) {
            System.err.println("❌ Error en búsqueda: " + e.getMessage());
        }
        return lista;
    }

    public boolean insertar(String nombre, int cantidad, double precio, String categoria) {
        String sql = "{call Add_Product(?, ?, ?, ?)}";
        try (Connection cn = ConexionBD.getConexion();
             CallableStatement cs = cn.prepareCall(sql)) {
            cs.setString(1, nombre);
            cs.setInt(2, cantidad);
            cs.setDouble(3, precio);
            cs.setString(4, categoria);
            cs.execute();
            return true;
        } catch (SQLException e) {
            System.err.println("❌ Error al insertar producto: " + e.getMessage());
            return false;
        }
    }

    public Producto buscarPorId(int id) {
        String sql = SELECT_BASE + "WHERE p.productid = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapear(rs);
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al buscar producto: " + e.getMessage());
        }
        return null;
    }

    public boolean eliminar(int id) {
        String sql = "DELETE FROM products WHERE productid = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("❌ Error al eliminar producto: " + e.getMessage());
            return false;
        }
    }

    public boolean actualizarStock(int productId, int nuevoStock) {
        String sql = "UPDATE products SET availablequantity = ? WHERE productid = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, nuevoStock);
            ps.setInt(2, productId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("❌ Error al actualizar stock: " + e.getMessage());
            return false;
        }
    }

    public boolean actualizarProducto(int id, String nombre, double precio, int categoriaId) {
        String sql = "UPDATE products SET productname = ?, unitprice = ?, categoryid = ? WHERE productid = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, nombre);
            ps.setDouble(2, precio);
            ps.setInt(3, categoriaId);
            ps.setInt(4, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("❌ Error al actualizar producto: " + e.getMessage());
            return false;
        }
    }

    // 🔥 MÉTODO CORREGIDO: Contar productos con bajo stock (solo los que tienen entre 1 y 49)
    public int contarProductosBajoStock(int limite) {
        String sql = "SELECT COUNT(*) FROM products WHERE availablequantity > 0 AND availablequantity < ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, limite);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al contar bajo stock: " + e.getMessage());
        }
        return 0;
    }

    // 🔥 NUEVO MÉTODO: Contar productos completamente agotados (stock = 0)
    public int contarProductosAgotados() {
        String sql = "SELECT COUNT(*) FROM products WHERE availablequantity = 0";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) {
            System.err.println("❌ Error al contar productos agotados: " + e.getMessage());
        }
        return 0;
    }

    public List<Object[]> obtenerListaBajoStock(int limite) {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT productname, availablequantity FROM products WHERE availablequantity < ? ORDER BY availablequantity ASC";
        
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, limite);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(new Object[]{ rs.getString("productname"), rs.getInt("availablequantity") });
                }
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al obtener lista de bajo stock: " + e.getMessage());
        }
        return lista;
    }
}