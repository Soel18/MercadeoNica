package com.mercadeonica.dao;

import com.mercadeonica.conexion.ConexionBD;
import com.mercadeonica.modelo.Cliente;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ClienteDAO {

    private static final String COLS_BASE =
        "c.customerid, c.name, c.email, c.city, c.state, c.zip, c.phone, " +
        "c.password_hash, c.active, c.categoryid, c.debe_cambiar_password, " +
        "cc.categoryname AS categoria_nombre, " +
        "cc.discount_percentage AS descuento, " +
        "ISNULL((SELECT COUNT(*) FROM orders o WHERE o.customerid = c.customerid AND o.status != 'CANCELADO'), 0) AS total_pedidos, " +
        "ISNULL((SELECT SUM(o.total) FROM orders o WHERE o.customerid = c.customerid AND o.status != 'CANCELADO'), 0) AS total_comprado ";

    private Cliente mapearCliente(ResultSet rs) throws SQLException {
        Cliente c = new Cliente();
        c.setCustomerId(rs.getInt("customerid"));
        c.setNombre(rs.getString("name"));
        c.setEmail(rs.getString("email"));
        c.setCiudad(rs.getString("city"));
        c.setEstado(rs.getString("state"));
        c.setZip(rs.getInt("zip"));
        c.setTelefono(rs.getString("phone"));
        c.setPasswordHash(rs.getString("password_hash"));
        c.setActive(rs.getBoolean("active"));
        c.setDebeCambiarPassword(rs.getBoolean("debe_cambiar_password"));

        int catId = rs.getInt("categoryid");
        if (!rs.wasNull()) c.setCategoryId(catId);
        c.setCategoriaNombre(rs.getString("categoria_nombre"));

        double desc = rs.getDouble("descuento");
        if (!rs.wasNull()) c.setDescuento(desc);

        try {
            c.setTotalPedidos(rs.getInt("total_pedidos"));
            c.setTotalComprado(rs.getDouble("total_comprado"));
        } catch (SQLException e) {
            c.setTotalPedidos(0);
            c.setTotalComprado(0);
        }
        return c;
    }

    public List<Cliente> listar() {
        List<Cliente> lista = new ArrayList<>();
        // 🔥 Solo mostramos clientes activos
        String sql = "SELECT " + COLS_BASE +
                     "FROM customers c " +
                     "LEFT JOIN CustomerCategories cc ON c.categoryid = cc.categoryid " +
                     "WHERE c.active = 1 " +
                     "ORDER BY c.name ASC, c.customerid ASC";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapearCliente(rs));
        } catch (SQLException e) {
            System.err.println("❌ Error al listar clientes: " + e.getMessage());
        }
        return lista;
    }

    public List<Cliente> buscarConFiltro(String q) {
        List<Cliente> lista = new ArrayList<>();
        // 🔥 Solo mostramos clientes activos que coincidan con la búsqueda
        String sql = "SELECT " + COLS_BASE +
                     "FROM customers c " +
                     "LEFT JOIN CustomerCategories cc ON c.categoryid = cc.categoryid " +
                     "WHERE c.active = 1 AND (c.name LIKE ? OR c.email LIKE ? OR c.phone LIKE ?) " +
                     "ORDER BY c.name ASC, c.customerid ASC";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            String like = "%" + q + "%";
            ps.setString(1, like);
            ps.setString(2, like);
            ps.setString(3, like);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapearCliente(rs));
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al buscar clientes: " + e.getMessage());
        }
        return lista;
    }

    public boolean insertar(String nombre, String email, String ciudad, String estado,
                            int zip, String telefono, String password, long tarjeta, String tipo, int mes, int anio) throws SQLException {
        String sql = "{call add_customer(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}";
        try (Connection cn = ConexionBD.getConexion();
             CallableStatement cs = cn.prepareCall(sql)) {
            cs.setString(1, nombre);
            cs.setString(2, email);
            cs.setString(3, ciudad);
            cs.setString(4, estado);
            cs.setInt   (5, zip);
            cs.setString(6, password);
            cs.setLong  (7, tarjeta);
            cs.setString(8, tipo);
            cs.setInt   (9, mes);
            cs.setInt   (10, anio);
            if (telefono != null && !telefono.isBlank()) cs.setString(11, telefono);
            else cs.setNull(11, Types.VARCHAR);
            cs.execute();
            return true;
        } catch (SQLException e) {
            System.err.println("❌ Error al insertar cliente en BD: " + e.getMessage());
            throw e;
        }
    }

    // 🔥 MÉTODO CORREGIDO: Borrado Lógico (Soft Delete)
    public boolean eliminar(int id) {
        String sql = "UPDATE customers SET active = 0 WHERE customerid = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            int filas = ps.executeUpdate();
            if (filas > 0) {
                System.out.println("✅ Cliente #" + id + " desactivado correctamente (Soft Delete).");
                return true;
            }
            return false;
        } catch (SQLException e) {
            System.err.println("❌ Error al desactivar cliente: " + e.getMessage());
            return false;
        }
    }

    public Cliente login(String email, String password) {
        String sql = "SELECT " + COLS_BASE +
                     "FROM customers c " +
                     "LEFT JOIN CustomerCategories cc ON c.categoryid = cc.categoryid " +
                     "WHERE c.email = ? AND c.active = 1";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String hashGuardado = rs.getString("password_hash");
                    if (hashGuardado != null && hashGuardado.equals(password)) {
                        Cliente c = mapearCliente(rs);
                        System.out.println("✅ Login de cliente: " + c.getNombre());
                        return c;
                    }
                }
            }
        } catch (SQLException e) {
            System.err.println("❌ Error en login de cliente: " + e.getMessage());
        }
        return null;
    }

    public boolean registrar(String nombre, String email, String ciudad, String estado,
                             int zip, String telefono, String password) throws SQLException {

        if (buscarPorEmail(email) != null) {
            System.out.println("⚠️ El email ya existe: " + email);
            return false;
        }

        String sql = "{call add_cliente_completo(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}";
        try (Connection cn = ConexionBD.getConexion();
             CallableStatement cs = cn.prepareCall(sql)) {

            cs.setString(1, nombre);
            cs.setString(2, email);
            cs.setString(3, ciudad);
            cs.setString(4, estado);
            cs.setInt   (5, zip);
            cs.setString(6, password);
            if (telefono != null && !telefono.isBlank()) cs.setString(7, telefono);
            else cs.setNull(7, Types.VARCHAR);
            cs.setNull  (8,  Types.BIGINT);
            cs.setNull  (9,  Types.VARCHAR);
            cs.setNull  (10, Types.INTEGER);
            cs.setNull  (11, Types.INTEGER);

            cs.execute();
            System.out.println("✅ SP add_cliente_completo OK para: " + email);
            return true;
        } catch (SQLException e) {
            System.err.println("❌ SQLException al registrar cliente: " + e.getMessage());
            throw e;
        }
    }

    public Cliente buscarPorEmail(String email) throws SQLException {
        String sql = "SELECT " + COLS_BASE +
                     "FROM customers c " +
                     "LEFT JOIN CustomerCategories cc ON c.categoryid = cc.categoryid " +
                     "WHERE c.email = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapearCliente(rs);
            }
        }
        return null;
    }

    public Cliente buscarPorNombre(String nombre) throws SQLException {
        String sql = "SELECT " + COLS_BASE +
                     "FROM customers c " +
                     "LEFT JOIN CustomerCategories cc ON c.categoryid = cc.categoryid " +
                     "WHERE UPPER(c.name) = UPPER(?)";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, nombre);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapearCliente(rs);
            }
        }
        return null;
    }

    public Cliente buscarPorTelefono(String telefono) throws SQLException {
        String sql = "SELECT " + COLS_BASE +
                     "FROM customers c " +
                     "LEFT JOIN CustomerCategories cc ON c.categoryid = cc.categoryid " +
                     "WHERE c.phone = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, telefono);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapearCliente(rs);
            }
        }
        return null;
    }

    public boolean tarjetaExiste(long tarjeta) {
        String sql = "SELECT COUNT(*) FROM creditcards WHERE creditcard = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setLong(1, tarjeta);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al verificar tarjeta: " + e.getMessage());
        }
        return false;
    }

    public Cliente buscarPorId(int id) {
        String sql = "SELECT " + COLS_BASE +
                     "FROM customers c " +
                     "LEFT JOIN CustomerCategories cc ON c.categoryid = cc.categoryid " +
                     "WHERE c.customerid = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapearCliente(rs);
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al buscar cliente por ID: " + e.getMessage());
        }
        return null;
    }

    public boolean cambiarCategoria(int customerId, int categoryId) {
        String sql = "UPDATE customers SET categoryid = ? WHERE customerid = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, categoryId);
            ps.setInt(2, customerId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("❌ Error al cambiar categoría: " + e.getMessage());
            return false;
        }
    }

    public boolean actualizar(int customerId, String nombre, String email, String telefono,
                              String ciudad, String estado, int zip) throws SQLException {

        Cliente existenteEmail = buscarPorEmail(email);
        if (existenteEmail != null && existenteEmail.getCustomerId() != customerId) {
            throw new IllegalArgumentException("El correo ya está registrado por otro cliente.");
        }

        String sql = "UPDATE customers SET name = ?, email = ?, phone = ?, " +
                     "city = ?, state = ?, zip = ? WHERE customerid = ?";

        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setString(1, nombre);
            ps.setString(2, email);
            if (telefono != null && !telefono.isBlank()) ps.setString(3, telefono);
            else ps.setNull(3, Types.VARCHAR);
            ps.setString(4, ciudad);
            ps.setString(5, estado);
            ps.setInt   (6, zip);
            ps.setInt   (7, customerId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            System.err.println("❌ Error al actualizar cliente: " + e.getMessage());
            throw e;
        }
    }
    
    public boolean actualizarPassword(int customerId, String nuevaPassword) {
        String sql = "UPDATE customers SET password_hash = ?, debe_cambiar_password = 0 WHERE customerid = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, nuevaPassword);
            ps.setInt(2, customerId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("❌ Error al actualizar contraseña: " + e.getMessage());
            return false;
        }
    }
}