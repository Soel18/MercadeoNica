package com.mercadeonica.dao;

import com.mercadeonica.conexion.ConexionBD;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class DashboardDAO {

    public int obtenerPedidosPendientes() {
        String sql = "SELECT COUNT(*) FROM orders WHERE status = 'PENDIENTE'";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public int obtenerTotalClientes() {
        String sql = "SELECT COUNT(*) FROM customers WHERE active = 1";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public int obtenerProductosBajoStock() {
        String sql = "SELECT COUNT(*) FROM products WHERE availablequantity < 50";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public double obtenerTotalFacturado(java.sql.Date inicio, java.sql.Date fin) {
        String sql = "SELECT ISNULL(SUM(total), 0) FROM orders WHERE status != 'CANCELADO' AND orderdate BETWEEN ? AND ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, inicio); ps.setDate(2, fin);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getDouble(1);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public double obtenerTicketPromedio(java.sql.Date inicio, java.sql.Date fin) {
        String sql = "SELECT ISNULL(AVG(total), 0) FROM orders WHERE status != 'CANCELADO' AND orderdate BETWEEN ? AND ?";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, inicio); ps.setDate(2, fin);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getDouble(1);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public double obtenerTotalFacturadoTodos() {
        String sql = "SELECT ISNULL(SUM(total), 0) FROM orders WHERE status != 'CANCELADO'";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getDouble(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public double obtenerTicketPromedioTodos() {
        String sql = "SELECT ISNULL(AVG(total), 0) FROM orders WHERE status != 'CANCELADO'";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getDouble(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public List<Object[]> obtenerPedidosPorEstadoTodos() {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT status, COUNT(*) AS cantidad FROM orders GROUP BY status";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(new Object[]{rs.getString("status"), rs.getInt("cantidad")});
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    public List<Object[]> obtenerVentasPorMesTodos() {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT FORMAT(orderdate, 'MMM yyyy') AS mes, SUM(total) AS total " +
                     "FROM orders WHERE status != 'CANCELADO' " +
                     "GROUP BY FORMAT(orderdate, 'MMM yyyy'), YEAR(orderdate), MONTH(orderdate) " +
                     "ORDER BY YEAR(orderdate) ASC, MONTH(orderdate) ASC";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(new Object[]{rs.getString("mes"), rs.getDouble("total")});
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    public List<Object[]> obtenerTopProductosTodos() {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT TOP 5 p.productname, SUM(od.quantity) AS total_vendido " +
                     "FROM order_details od " +
                     "JOIN products p ON od.productid = p.productid " +
                     "JOIN orders o ON od.orderid = o.orderid " +
                     "WHERE o.status != 'CANCELADO' " +
                     "GROUP BY p.productname ORDER BY total_vendido DESC";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(new Object[]{rs.getString("productname"), rs.getInt("total_vendido")});
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    public List<Object[]> obtenerTopClientesTodos() {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT TOP 5 c.name, SUM(o.total) AS total_gastado " +
                     "FROM orders o JOIN customers c ON o.customerid = c.customerid " +
                     "WHERE o.status != 'CANCELADO' " +
                     "GROUP BY c.name ORDER BY total_gastado DESC";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(new Object[]{rs.getString("name"), rs.getDouble("total_gastado")});
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    // 🔥 CORREGIDO: INNER JOIN y HAVING para filtrar solo los que tienen ventas
    public List<Object[]> obtenerVentasPorVendedor(java.sql.Date inicio, java.sql.Date fin) {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT s.name, ISNULL(SUM(o.total), 0) AS total_vendido " +
                     "FROM sellers s " +
                     "INNER JOIN orders o ON s.sellerid = o.sellerid " +
                     "WHERE o.status != 'CANCELADO' AND o.orderdate BETWEEN ? AND ? " +
                     "GROUP BY s.name " +
                     "HAVING ISNULL(SUM(o.total), 0) > 0 " +
                     "ORDER BY total_vendido DESC";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, inicio); ps.setDate(2, fin);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(new Object[]{rs.getString("name"), rs.getDouble("total_vendido")});
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    // 🔥 CORREGIDO: INNER JOIN y HAVING para filtrar solo los que tienen ventas
    public List<Object[]> obtenerVentasPorVendedorTodos() {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT s.name, ISNULL(SUM(o.total), 0) AS total_vendido " +
                     "FROM sellers s " +
                     "INNER JOIN orders o ON s.sellerid = o.sellerid " +
                     "WHERE o.status != 'CANCELADO' " +
                     "GROUP BY s.name " +
                     "HAVING ISNULL(SUM(o.total), 0) > 0 " +
                     "ORDER BY total_vendido DESC";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(new Object[]{rs.getString("name"), rs.getDouble("total_vendido")});
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    public List<Object[]> obtenerVentasPorMes(java.sql.Date inicio, java.sql.Date fin) {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT FORMAT(orderdate, 'MMM yyyy') AS mes, SUM(total) AS total " +
                     "FROM orders WHERE orderdate BETWEEN ? AND ? AND status != 'CANCELADO' " +
                     "GROUP BY FORMAT(orderdate, 'MMM yyyy'), YEAR(orderdate), MONTH(orderdate) " +
                     "ORDER BY YEAR(orderdate) ASC, MONTH(orderdate) ASC";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, inicio); ps.setDate(2, fin);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(new Object[]{rs.getString("mes"), rs.getDouble("total")});
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    public List<Object[]> obtenerPedidosPorEstado(java.sql.Date inicio, java.sql.Date fin) {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT status, COUNT(*) AS cantidad FROM orders WHERE orderdate BETWEEN ? AND ? GROUP BY status";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, inicio); ps.setDate(2, fin);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(new Object[]{rs.getString("status"), rs.getInt("cantidad")});
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    public List<Object[]> obtenerTopProductos(java.sql.Date inicio, java.sql.Date fin) {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT TOP 5 p.productname, SUM(od.quantity) AS total_vendido " +
                     "FROM order_details od " +
                     "JOIN products p ON od.productid = p.productid " +
                     "JOIN orders o ON od.orderid = o.orderid " +
                     "WHERE o.orderdate BETWEEN ? AND ? AND o.status != 'CANCELADO' " +
                     "GROUP BY p.productname ORDER BY total_vendido DESC";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, inicio); ps.setDate(2, fin);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(new Object[]{rs.getString("productname"), rs.getInt("total_vendido")});
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    public List<Object[]> obtenerTopClientes(java.sql.Date inicio, java.sql.Date fin) {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT TOP 5 c.name, SUM(o.total) AS total_gastado " +
                     "FROM orders o JOIN customers c ON o.customerid = c.customerid " +
                     "WHERE o.status != 'CANCELADO' AND o.orderdate BETWEEN ? AND ? " +
                     "GROUP BY c.name ORDER BY total_gastado DESC";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, inicio); ps.setDate(2, fin);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(new Object[]{rs.getString("name"), rs.getDouble("total_gastado")});
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    public List<Object[]> obtenerClientesPorCategoria() {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT ISNULL(cc.categoryname, 'Sin Categoría') AS cat, COUNT(c.customerid) AS cantidad " +
                     "FROM customers c LEFT JOIN CustomerCategories cc ON c.categoryid = cc.categoryid " +
                     "GROUP BY cc.categoryname";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(new Object[]{rs.getString("cat"), rs.getInt("cantidad")});
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    public List<Object[]> obtenerListaBajoStock() {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT TOP 5 productname, availablequantity FROM products " +
                     "WHERE availablequantity < 50 ORDER BY availablequantity ASC";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(new Object[]{rs.getString("productname"), rs.getInt("availablequantity")});
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    // ============================================================
    // 🔥 NUEVOS MÉTODOS PARA LOS 6 PUNTOS DEL DASHBOARD
    // ============================================================

    public List<Object[]> obtenerVentasPorHora(java.sql.Date inicio, java.sql.Date fin) {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT DATEPART(hour, orderdate) AS hora, SUM(total) AS total " +
                     "FROM orders WHERE status != 'CANCELADO' AND orderdate BETWEEN ? AND ? " +
                     "GROUP BY DATEPART(hour, orderdate) ORDER BY hora";
        try (Connection cn = ConexionBD.getConexion(); PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, inicio); 
            ps.setDate(2, fin);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int horaNum = rs.getInt("hora");
                    String horaFormateada = String.format("%02d:00", horaNum);
                    lista.add(new Object[]{horaFormateada, rs.getDouble("total")});
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    public List<Object[]> obtenerVentasPorCategoriaProducto(java.sql.Date inicio, java.sql.Date fin) {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT c.categoryname, SUM(od.quantity * od.unitprice) AS total " +
                     "FROM order_details od " +
                     "JOIN products p ON od.productid = p.productid " +
                     "JOIN ProductCategories c ON p.categoryid = c.categoryid " +
                     "JOIN orders o ON od.orderid = o.orderid " +
                     "WHERE o.status != 'CANCELADO' AND o.orderdate BETWEEN ? AND ? " +
                     "GROUP BY c.categoryname ORDER BY total DESC";
        try (Connection cn = ConexionBD.getConexion(); PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, inicio); ps.setDate(2, fin);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(new Object[]{rs.getString("categoryname"), rs.getDouble("total")});
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    public List<Object[]> obtenerMetodosDePago(java.sql.Date inicio, java.sql.Date fin) {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT ISNULL(cc.creditcard_type, 'Efectivo') AS tipo, COUNT(o.orderid) AS cantidad " +
                     "FROM orders o " +
                     "LEFT JOIN creditcards cc ON o.cc_number = cc.creditcard " +
                     "WHERE o.status != 'CANCELADO' AND o.orderdate BETWEEN ? AND ? " +
                     "GROUP BY cc.creditcard_type ORDER BY cantidad DESC";
        try (Connection cn = ConexionBD.getConexion(); PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, inicio); 
            ps.setDate(2, fin);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(new Object[]{rs.getString("tipo"), rs.getInt("cantidad")});
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    public List<Object[]> obtenerTopProductosCalificados() {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT TOP 5 p.productname, AVG(CAST(r.starsgiven AS DECIMAL(10,2))) AS promedio " +
                     "FROM reviews r JOIN products p ON r.productid = p.productid " +
                     "GROUP BY p.productname ORDER BY promedio DESC";
        try (Connection cn = ConexionBD.getConexion();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(new Object[]{rs.getString("productname"), rs.getDouble("promedio")});
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    public List<Object[]> obtenerVentasPorMesAnterior(java.sql.Date inicio, java.sql.Date fin) {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT FORMAT(orderdate, 'MMM yyyy') AS mes, SUM(total) AS total " +
                     "FROM orders WHERE orderdate BETWEEN ? AND ? AND status != 'CANCELADO' " +
                     "GROUP BY FORMAT(orderdate, 'MMM yyyy'), YEAR(orderdate), MONTH(orderdate) " +
                     "ORDER BY YEAR(orderdate) ASC, MONTH(orderdate) ASC";
        try (Connection cn = ConexionBD.getConexion(); PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, inicio); ps.setDate(2, fin);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(new Object[]{rs.getString("mes"), rs.getDouble("total")});
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }
}