package com.mercadeonica.dao;

import com.mercadeonica.conexion.ConexionBD;
import com.mercadeonica.modelo.Categoria;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO para la tabla 'ProductCategories'.
 */
public class CategoriaDAO {

    /**
     * Lista todas las categorías ordenadas alfabéticamente por nombre.
     */
    public List<Categoria> listar() {
        List<Categoria> lista = new ArrayList<>();
        String sql = "SELECT categoryid, categoryname, description " +
                     "FROM ProductCategories ORDER BY categoryname ASC";

        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                lista.add(new Categoria(
                        rs.getInt("categoryid"),
                        rs.getString("categoryname"),
                        rs.getString("description")
                ));
            }
        } catch (SQLException e) {
            System.err.println("❌ Error al listar categorías: " + e.getMessage());
        }
        return lista;
    }

    /**
     * Inserta una nueva categoría.
     */
    public boolean insertar(String nombre, String descripcion) {
        String sql = "{call Add_Category(?, ?)}";
        try (Connection cn = ConexionBD.getConexion();
             CallableStatement cs = cn.prepareCall(sql)) {

            cs.setString(1, nombre);
            cs.setString(2, descripcion);
            cs.execute();
            return true;
        } catch (SQLException e) {
            System.err.println("❌ Error al insertar categoría: " + e.getMessage());
            return false;
        }
    }
}