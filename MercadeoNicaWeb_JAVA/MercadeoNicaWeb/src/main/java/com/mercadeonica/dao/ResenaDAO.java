package com.mercadeonica.dao;

import com.mercadeonica.conexion.ConexionBD;
import com.mercadeonica.modelo.Resena;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * DAO para la tabla 'reviews'.
 * Nota: la tabla 'reviews' no tiene customerid ni fecha en el esquema original.
 * Usamos reviewer_email para identificar al cliente.
 */
public class ResenaDAO {

    private Resena mapear(ResultSet rs) throws SQLException {
        Resena r = new Resena();
        r.setReviewId(rs.getInt("reviewid"));
        r.setProductId(rs.getInt("productid"));
        r.setReviewerEmail(rs.getString("reviewer_email"));
        r.setEstrellas(rs.getInt("starsgiven"));
        r.setComentario(rs.getString("review_text"));
        try { r.setProductName(rs.getString("productname")); } catch (SQLException ignored) {}
        return r;
    }

    /**
     * Lista TODAS las reseñas del sistema (para admin).
     */
    public List<Resena> listarTodas() {
        List<Resena> lista = new ArrayList<>();
        String sql = "SELECT r.reviewid, r.productid, r.reviewer_email, r.starsgiven, " +
                     "r.review_text, p.productname " +
                     "FROM reviews r LEFT JOIN products p ON r.productid = p.productid " +
                     "ORDER BY r.reviewid DESC";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapear(rs));
        } catch (SQLException e) {
            System.err.println("❌ Error al listar reseñas: " + e.getMessage());
        }
        return lista;
    }

    /**
     * Lista las reseñas de UN cliente (por email).
     */
    public List<Resena> listarPorCliente(String email) {
        List<Resena> lista = new ArrayList<>();
        String sql = "SELECT r.reviewid, r.productid, r.reviewer_email, r.starsgiven, " +
                     "r.review_text, p.productname " +
                     "FROM reviews r LEFT JOIN products p ON r.productid = p.productid " +
                     "WHERE r.reviewer_email = ? " +
                     "ORDER BY r.reviewid DESC";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapear(rs));
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al listar reseñas del cliente: " + e.getMessage());
        }
        return lista;
    }

    /**
     * Lista las reseñas de UN producto.
     */
    public List<Resena> listarPorProducto(int productId) {
        List<Resena> lista = new ArrayList<>();
        String sql = "SELECT r.reviewid, r.productid, r.reviewer_email, r.starsgiven, " +
                     "r.review_text, p.productname " +
                     "FROM reviews r LEFT JOIN products p ON r.productid = p.productid " +
                     "WHERE r.productid = ? " +
                     "ORDER BY r.reviewid DESC";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapear(rs));
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al listar reseñas del producto: " + e.getMessage());
        }
        return lista;
    }

    /**
     * Obtiene el promedio y cantidad de reseñas por producto.
     * Map<productId, Map<promedio, total>>
     */
    public Map<Integer, Double> obtenerPromedios() {
        Map<Integer, Double> map = new HashMap<>();
        String sql = "SELECT productid, AVG(CAST(starsgiven AS DECIMAL(10,2))) AS promedio " +
                     "FROM reviews GROUP BY productid";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                map.put(rs.getInt("productid"), rs.getDouble("promedio"));
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al obtener promedios: " + e.getMessage());
        }
        return map;
    }

    /**
     * Obtiene el promedio y total de reseñas de un solo producto.
     * Devuelve [promedio, total] o [0.0, 0] si no hay reseñas.
     */
    public double[] obtenerPromedioProducto(int productId) {
        String sql = "SELECT AVG(CAST(starsgiven AS DECIMAL(10,2))) AS promedio, " +
                     "COUNT(*) AS total " +
                     "FROM reviews WHERE productid = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new double[]{ rs.getDouble("promedio"), rs.getInt("total") };
                }
            }
        } catch (SQLException e) {
            System.err.println("❌ Error: " + e.getMessage());
        }
        return new double[]{ 0.0, 0 };
    }

    /**
     * ¿Existe ya una reseña del cliente (email) para este producto?
     */
    public boolean yaReseno(String email, int productId) {
        String sql = "SELECT COUNT(*) FROM reviews " +
                     "WHERE reviewer_email = ? AND productid = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, email);
            ps.setInt(2, productId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            System.err.println("❌ Error: " + e.getMessage());
        }
        return false;
    }

    /**
     * ¿El cliente compró este producto en algún pedido ENTREGADO?
     */
    public boolean comproProducto(String email, int productId) {
        String sql = "SELECT COUNT(*) " +
                     "FROM order_details od " +
                     "JOIN orders o ON od.orderid = o.orderid " +
                     "JOIN customers c ON o.customerid = c.customerid " +
                     "WHERE c.email = ? AND od.productid = ? AND o.status = 'ENTREGADO'";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, email);
            ps.setInt(2, productId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            System.err.println("❌ Error: " + e.getMessage());
        }
        return false;
    }

    /**
     * Lista los productos que el cliente COMPRÓ y AÚN NO ha reseñado.
     * Para sugerirle "reseña estos productos".
     */
    public List<Map<String, Object>> productosPendientesDeResenar(String email) {
        List<Map<String, Object>> lista = new ArrayList<>();
        String sql =
            "SELECT DISTINCT p.productid, p.productname " +
            "FROM order_details od " +
            "JOIN orders o    ON od.orderid   = o.orderid " +
            "JOIN customers c ON o.customerid = c.customerid " +
            "JOIN products p  ON od.productid = p.productid " +
            "WHERE c.email = ? AND o.status = 'ENTREGADO' " +
            "  AND p.productid NOT IN ( " +
            "      SELECT productid FROM reviews WHERE reviewer_email = ? " +
            "  ) " +
            "ORDER BY p.productname";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, email);
            ps.setString(2, email);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("productId", rs.getInt("productid"));
                    m.put("productName", rs.getString("productname"));
                    lista.add(m);
                }
            }
        } catch (SQLException e) {
            System.err.println("❌ Error: " + e.getMessage());
        }
        return lista;
    }

    /**
     * Agrega una reseña nueva.
     * @return null si OK, mensaje de error si falla.
     */
    public String agregar(Resena r) {
        // Validar que no haya reseñado ya este producto
        if (yaReseno(r.getReviewerEmail(), r.getProductId())) {
            return "Ya dejaste una reseña para este producto. Puedes editarla o eliminarla.";
        }

        // Validar que compró el producto
        if (!comproProducto(r.getReviewerEmail(), r.getProductId())) {
            return "Solo puedes reseñar productos que hayas comprado y recibido (ENTREGADO).";
        }

        String sql = "INSERT INTO reviews (productid, reviewer_email, starsgiven, review_text) " +
                     "VALUES (?, ?, ?, ?)";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, r.getProductId());
            ps.setString(2, r.getReviewerEmail());
            ps.setInt(3, r.getEstrellas());
            ps.setString(4, r.getComentario());
            ps.executeUpdate();
            System.out.println("✅ Reseña agregada para producto " + r.getProductId());
            return null;
        } catch (SQLException e) {
            System.err.println("❌ Error al agregar reseña: " + e.getMessage());
            return "Error de BD: " + e.getMessage();
        }
    }

    /**
     * Actualiza una reseña existente (solo si pertenece al email).
     */
    public String actualizar(int reviewId, String email, int estrellas, String comentario) {
        String sql = "UPDATE reviews SET starsgiven = ?, review_text = ? " +
                     "WHERE reviewid = ? AND reviewer_email = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, estrellas);
            ps.setString(2, comentario);
            ps.setInt(3, reviewId);
            ps.setString(4, email);
            int filas = ps.executeUpdate();
            if (filas > 0) {
                System.out.println("✅ Reseña actualizada: " + reviewId);
                return null;
            }
            return "No se encontró la reseña o no te pertenece.";
        } catch (SQLException e) {
            System.err.println("❌ Error al actualizar reseña: " + e.getMessage());
            return "Error de BD: " + e.getMessage();
        }
    }

    /**
     * Elimina una reseña. Si esAdmin=true, puede eliminar cualquiera.
     */
    public String eliminar(int reviewId, String email, boolean esAdmin) {
        String sql = esAdmin
            ? "DELETE FROM reviews WHERE reviewid = ?"
            : "DELETE FROM reviews WHERE reviewid = ? AND reviewer_email = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, reviewId);
            if (!esAdmin) ps.setString(2, email);
            int filas = ps.executeUpdate();
            if (filas > 0) {
                System.out.println("✅ Reseña eliminada: " + reviewId);
                return null;
            }
            return "No se encontró la reseña o no tienes permiso.";
        } catch (SQLException e) {
            System.err.println("❌ Error al eliminar reseña: " + e.getMessage());
            return "Error de BD: " + e.getMessage();
        }
    }

    /**
     * Obtiene una reseña por ID.
     */
    public Resena buscarPorId(int reviewId) {
        String sql = "SELECT r.reviewid, r.productid, r.reviewer_email, r.starsgiven, " +
                     "r.review_text, p.productname " +
                     "FROM reviews r LEFT JOIN products p ON r.productid = p.productid " +
                     "WHERE r.reviewid = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, reviewId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapear(rs);
            }
        } catch (SQLException e) {
            System.err.println("❌ Error: " + e.getMessage());
        }
        return null;
    }
}