package com.mercadeonica.dao;

import com.mercadeonica.conexion.ConexionBD;
import com.mercadeonica.modelo.Tarjeta;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class TarjetaDAO {

    /**
     * Lista todas las tarjetas de un cliente.
     */
    public List<Tarjeta> listarPorCliente(int customerId) {
        List<Tarjeta> lista = new ArrayList<>();
        String sql = "SELECT customerid, creditcard, creditcard_type, " +
                     "expiration_month, expiration_year " +
                     "FROM creditcards WHERE customerid = ? " +
                     "ORDER BY expiration_year DESC, expiration_month DESC";

        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setInt(1, customerId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Tarjeta t = new Tarjeta();
                    t.setCustomerId(rs.getInt("customerid"));
                    t.setNumero(rs.getLong("creditcard"));
                    t.setTipo(rs.getString("creditcard_type"));
                    t.setMesExpiracion(rs.getInt("expiration_month"));
                    t.setAnioExpiracion(rs.getInt("expiration_year"));
                    lista.add(t);
                }
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al listar tarjetas: " + e.getMessage());
        }
        return lista;
    }

    /**
     * Verifica si ya existe esa tarjeta en el sistema (PK global).
     */
    public boolean existeTarjeta(long numero) {
        String sql = "SELECT COUNT(*) FROM creditcards WHERE creditcard = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setLong(1, numero);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al verificar tarjeta: " + e.getMessage());
        }
        return false;
    }

    /**
     * Agrega una tarjeta nueva.
     * @return null si OK, mensaje de error si falla.
     */
    public String agregar(Tarjeta t) {
        if (existeTarjeta(t.getNumero())) {
            return "Esa tarjeta ya está registrada en el sistema. " +
                   "Si es tuya y pertenece a otra cuenta, contacta al administrador.";
        }

        String sql = "INSERT INTO creditcards (customerid, creditcard, creditcard_type, " +
                     "expiration_month, expiration_year) VALUES (?, ?, ?, ?, ?)";

        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setInt(1, t.getCustomerId());
            ps.setLong(2, t.getNumero());
            ps.setString(3, t.getTipo());
            ps.setInt(4, t.getMesExpiracion());
            ps.setInt(5, t.getAnioExpiracion());
            ps.executeUpdate();
            System.out.println("✅ Tarjeta agregada para cliente " + t.getCustomerId());
            return null;

        } catch (SQLException e) {
            System.err.println("❌ Error al agregar tarjeta: " + e.getMessage());
            return "Error de BD: " + e.getMessage();
        }
    }

    /**
     * Elimina una tarjeta SI pertenece al cliente y NO tiene facturas asociadas.
     * @return null si OK, mensaje de error si falla.
     */
    public String eliminar(long numero, int customerId) {

        // 1. Verificar que la tarjeta pertenece al cliente
        String sqlVerif = "SELECT COUNT(*) FROM creditcards " +
                          "WHERE creditcard = ? AND customerid = ?";

        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sqlVerif)) {
            ps.setLong(1, numero);
            ps.setInt(2, customerId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getInt(1) == 0) {
                    return "La tarjeta no existe o no te pertenece.";
                }
            }
        } catch (SQLException e) {
            return "Error de BD: " + e.getMessage();
        }

        // 2. Verificar que no tenga facturas asociadas
        String sqlFact = "SELECT COUNT(*) FROM invoices WHERE creditcard = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sqlFact)) {
            ps.setLong(1, numero);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) {
                    int n = rs.getInt(1);
                    return "No se puede eliminar: esta tarjeta está asociada a " +
                           n + " factura(s). Si deseas eliminarla, contacta al administrador.";
                }
            }
        } catch (SQLException e) {
            return "Error de BD: " + e.getMessage();
        }

        // 3. Eliminar
        String sqlDel = "DELETE FROM creditcards WHERE creditcard = ? AND customerid = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sqlDel)) {
            ps.setLong(1, numero);
            ps.setInt(2, customerId);
            int filas = ps.executeUpdate();
            if (filas > 0) {
                System.out.println("✅ Tarjeta eliminada: " + numero);
                return null;
            }
            return "No se pudo eliminar la tarjeta.";
        } catch (SQLException e) {
            return "Error de BD: " + e.getMessage();
        }
    }

    /**
     * Verifica que una tarjeta exista Y pertenezca al cliente dado.
     * Útil antes de confirmar un pedido.
     */
    public boolean perteneceACliente(long numero, int customerId) {
        String sql = "SELECT COUNT(*) FROM creditcards " +
                     "WHERE creditcard = ? AND customerid = ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setLong(1, numero);
            ps.setInt(2, customerId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            System.err.println("❌ Error: " + e.getMessage());
        }
        return false;
    }
}