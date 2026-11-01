package com.mercadeonica.dao;

import com.mercadeonica.conexion.ConexionBD;
import com.mercadeonica.modelo.CategoriaCliente;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO para la tabla 'CustomerCategories'.
 */
public class CategoriaClienteDAO {

    /**
     * Lista todas las categorías de cliente ordenadas alfabéticamente por nombre.
     */
    public List<CategoriaCliente> listar() {
        List<CategoriaCliente> lista = new ArrayList<>();

        // 🔥 CORREGIDO: La tabla no tiene 'description', solo categoryid, categoryname y discount_percentage
        String sql = "SELECT categoryid, categoryname, discount_percentage " +
                     "FROM CustomerCategories ORDER BY categoryid ASC";

        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                lista.add(new CategoriaCliente(
                        rs.getInt("categoryid"),
                        rs.getString("categoryname"),
                        rs.getDouble("discount_percentage"),
                        null // 🔥 No hay descripción en la tabla, se pasa null
                ));
            }
            
            System.out.println("✅ Categorías de cliente cargadas desde BD: " + lista.size());

        } catch (SQLException e) {
            System.err.println("❌ Error al listar categorías: " + e.getMessage());
            e.printStackTrace();
        }
        return lista;
    }

    public CategoriaCliente buscarPorId(int id) {
        String sql = "SELECT categoryid, categoryname, discount_percentage " +
                     "FROM CustomerCategories WHERE categoryid = ?";

        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setInt(1, id);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new CategoriaCliente(
                            rs.getInt("categoryid"),
                            rs.getString("categoryname"),
                            rs.getDouble("discount_percentage"),
                            null
                    );
                }
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al buscar categoría: " + e.getMessage());
        }
        return null;
    }

    public boolean insertar(String nombre, double descuento, String descripcion) {
        // 🔥 CORREGIDO: Quitamos 'description' del INSERT
        String sql = "INSERT INTO CustomerCategories (categoryname, discount_percentage) " +
                     "VALUES (?, ?)";

        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setString(1, nombre);
            ps.setDouble(2, descuento);
            ps.executeUpdate();
            System.out.println("✅ Categoría insertada: " + nombre);
            return true;

        } catch (SQLException e) {
            System.err.println("❌ Error al insertar categoría: " + e.getMessage());
            return false;
        }
    }
}