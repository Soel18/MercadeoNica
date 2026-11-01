package com.mercadeonica.dao;

import com.mercadeonica.conexion.ConexionBD;
import com.mercadeonica.modelo.Vendedor;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class VendedorDAO {

    public Vendedor login(String email, String password) {
        String sql = "SELECT sellerid, name, email, phone, password_hash, role, active " +
                     "FROM sellers WHERE email = ? AND active = 1";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String hashGuardado = rs.getString("password_hash");
                    if (hashGuardado.equals(password)) {
                        Vendedor v = new Vendedor(
                                rs.getInt("sellerid"),
                                rs.getString("name"),
                                rs.getString("email"),
                                hashGuardado,
                                rs.getString("role"),
                                rs.getBoolean("active"));
                        v.setTelefono(rs.getString("phone"));
                        System.out.println("✅ Login exitoso: " + v.getNombre());
                        return v;
                    }
                }
            }
        } catch (SQLException e) {
            System.err.println("❌ Error en login: " + e.getMessage());
        }
        return null;
    }

    public Vendedor buscarPorId(int sellerId) {
        String sql = "SELECT sellerid, name, email, phone, password_hash, role, active " +
                     "FROM sellers WHERE sellerid = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, sellerId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Vendedor v = new Vendedor(
                            rs.getInt("sellerid"),
                            rs.getString("name"),
                            rs.getString("email"),
                            rs.getString("password_hash"),
                            rs.getString("role"),
                            rs.getBoolean("active"));
                    v.setTelefono(rs.getString("phone"));
                    return v;
                }
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al buscar vendedor: " + e.getMessage());
        }
        return null;
    }

    public List<Vendedor> listar() {
        List<Vendedor> lista = new ArrayList<>();
        String sql = "SELECT sellerid, name, email, phone, password_hash, role, active " +
                     "FROM sellers ORDER BY sellerid";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Vendedor v = new Vendedor(
                        rs.getInt("sellerid"),
                        rs.getString("name"),
                        rs.getString("email"),
                        rs.getString("password_hash"),
                        rs.getString("role"),
                        rs.getBoolean("active"));
                v.setTelefono(rs.getString("phone"));
                lista.add(v);
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al listar vendedores: " + e.getMessage());
        }
        return lista;
    }

    public boolean insertar(String nombre, String email, String password, String rol) {
        return insertar(nombre, email, null, password, rol);
    }

    public boolean insertar(String nombre, String email, String telefono,
                            String password, String rol) {
        String sql = "INSERT INTO sellers (name, email, phone, password_hash, role, active) " +
                     "VALUES (?, ?, ?, ?, ?, 1)";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, nombre);
            ps.setString(2, email);
            if (telefono != null && !telefono.isBlank()) ps.setString(3, telefono);
            else ps.setNull(3, Types.VARCHAR);
            ps.setString(4, password);
            ps.setString(5, rol);
            ps.executeUpdate();
            System.out.println("✅ Vendedor insertado: " + nombre);
            return true;
        } catch (SQLException e) {
            System.err.println("❌ Error al insertar vendedor: " + e.getMessage());
            return false;
        }
    }

    public boolean eliminar(int id) {
        String sql = "DELETE FROM sellers WHERE sellerid = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("❌ Error al eliminar vendedor: " + e.getMessage());
            return false;
        }
    }

    public boolean cambiarEstado(int id, boolean activo) {
        String sql = "UPDATE sellers SET active = ? WHERE sellerid = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setBoolean(1, activo);
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("❌ Error al cambiar estado: " + e.getMessage());
            return false;
        }
    }

    public boolean cambiarPasswordAdmin(int sellerId, String passwordNueva) {
        String sql = "UPDATE sellers SET password_hash = ? WHERE sellerid = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, passwordNueva);
            ps.setInt(2, sellerId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("❌ Error al cambiar contraseña: " + e.getMessage());
            return false;
        }
    }

    // ============================================================
    // 🔥 NUEVO: ACTUALIZAR DATOS DEL VENDEDOR
    // ============================================================

    /**
     * Verifica si el email ya está en uso por OTRO vendedor.
     * @param sellerId  ID del vendedor que estamos editando (para excluirlo)
     * @param email     Email a verificar
     * @return true si ya existe en OTRO vendedor
     */
    public boolean existeEmailEnOtro(int sellerId, String email) {
        String sql = "SELECT COUNT(*) FROM sellers WHERE email = ? AND sellerid <> ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, email);
            ps.setInt(2, sellerId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al verificar email: " + e.getMessage());
        }
        return false;
    }

    /**
     * Actualiza nombre, email, teléfono y rol de un vendedor.
     * @return null si OK, mensaje de error si falla.
     */
    public String actualizar(int sellerId, String nombre, String email,
                             String telefono, String rol) {

        // Validar que el email no esté en uso por OTRO vendedor
        if (existeEmailEnOtro(sellerId, email)) {
            return "El correo '" + email + "' ya está registrado por otro vendedor.";
        }

        String sql = "UPDATE sellers SET name = ?, email = ?, phone = ?, role = ? " +
                     "WHERE sellerid = ?";

        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setString(1, nombre);
            ps.setString(2, email);
            if (telefono != null && !telefono.isBlank()) ps.setString(3, telefono);
            else ps.setNull(3, Types.VARCHAR);
            ps.setString(4, rol);
            ps.setInt(5, sellerId);

            int filas = ps.executeUpdate();
            if (filas > 0) {
                System.out.println("✅ Vendedor ID " + sellerId + " actualizado.");
                return null;
            }
            return "No se encontró el vendedor o no se pudo actualizar.";

        } catch (SQLException e) {
            System.err.println("❌ Error al actualizar vendedor: " + e.getMessage());
            return "Error de BD: " + e.getMessage();
        }
    }
}