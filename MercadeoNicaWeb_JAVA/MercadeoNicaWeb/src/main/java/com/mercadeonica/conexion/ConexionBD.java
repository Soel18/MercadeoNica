package com.mercadeonica.conexion;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * Clase de conexión a la base de datos OSF (SQL Server).
 *
 * Sistema: OLINNE SALES FORCE (OSF) OSF2026admin!
 * Base de datos: OSF
 * Servidor: localhost\SQLEXPRESS
 */
public class ConexionBD {

    // ---------- Configuración de la conexión ----------
    private static final String SERVIDOR  = "localhost";
    private static final String BASE      = "OSF";
    private static final String USUARIO   = "sa";
    private static final String PASSWORD  = "Contrasenia123";

    private static final String URL =
            "jdbc:sqlserver://" + SERVIDOR + ";"
            + "databaseName=" + BASE + ";"
            + "encrypt=true;trustServerCertificate=true;";

    // ---------- Cargar el driver JDBC al iniciar la clase ----------
    static {
        try {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            System.out.println("✅ Driver JDBC cargado correctamente.");
        } catch (ClassNotFoundException e) {
            System.err.println("❌ Driver JDBC no encontrado: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * Devuelve una nueva conexión a la base de datos OSF.
     * @return Connection activa
     * @throws SQLException si falla la conexión
     */
    public static Connection getConexion() throws SQLException {
        return DriverManager.getConnection(URL, USUARIO, PASSWORD);
    }

    /**
     * Método de prueba: verifica la conexión y consulta datos.
     * Ejecuta esta clase con Shift + F6 en NetBeans.
     */
    public static void main(String[] args) {
        System.out.println("========== PRUEBA DE CONEXIÓN ==========");

        try (Connection cn = getConexion()) {

            System.out.println("✅ Conexión exitosa");
            System.out.println("   URL: " + cn.getMetaData().getURL());
            System.out.println("   Usuario: " + cn.getMetaData().getUserName());
            System.out.println("   Base de datos: " + cn.getCatalog());
            System.out.println("   Servidor: " + cn.getMetaData().getDatabaseProductName());
            System.out.println("   Versión: " + cn.getMetaData().getDatabaseProductVersion());

            // Ver cuántos clientes hay
            Statement st = cn.createStatement();
            ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM customers");
            if (rs.next()) {
                System.out.println("   Total de clientes: " + rs.getInt(1));
            }
            rs.close();

            // Ver el ID máximo de cliente
            rs = st.executeQuery("SELECT MAX(customerid) FROM customers");
            if (rs.next()) {
                System.out.println("   ID máximo de cliente: " + rs.getInt(1));
            }
            rs.close();

            // Ver cuántos productos hay
            rs = st.executeQuery("SELECT COUNT(*) FROM products");
            if (rs.next()) {
                System.out.println("   Total de productos: " + rs.getInt(1));
            }
            rs.close();

            // Ver cuántos vendedores hay
            rs = st.executeQuery("SELECT COUNT(*) FROM sellers");
            if (rs.next()) {
                System.out.println("   Total de vendedores: " + rs.getInt(1));
            }
            rs.close();

            st.close();

        } catch (SQLException e) {
            System.err.println("❌ Error de conexión: " + e.getMessage());
            System.err.println("--------------------------------------------------");
            System.err.println("Verifica:");
            System.err.println("  - Que SQL Server esté corriendo");
            System.err.println("  - Que SQL Server Browser esté corriendo");
            System.err.println("  - Que TCP/IP esté habilitado");
            System.err.println("  - Que el usuario 'sa' tenga permisos");
            System.err.println("  - Que la BD 'OSF' exista");
            e.printStackTrace();
        }

        System.out.println("=======================================");
    }
}