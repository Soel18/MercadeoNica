<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="com.mercadeonica.modelo.Vendedor" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    Vendedor vendedor = (Vendedor) session.getAttribute("vendedor");
    if (vendedor == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    List<Map<String, Object>> inventario      = (List<Map<String, Object>>) request.getAttribute("inventario");
    List<Map<String, Object>> mejoresClientes = (List<Map<String, Object>>) request.getAttribute("mejoresClientes");
    List<Map<String, Object>> ventasVendedor  = (List<Map<String, Object>>) request.getAttribute("ventasVendedor");
    List<Map<String, Object>> movimientos     = (List<Map<String, Object>>) request.getAttribute("movimientos");
    List<Map<String, Object>> resenas         = (List<Map<String, Object>>) request.getAttribute("resenas");
    Map<String, Object> estadisticas          = (Map<String, Object>) request.getAttribute("estadisticas");

    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reportes - MercadeoNica</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body>

    <header>
        <h1>🛒 MercadeoNica</h1>
                <nav>
            <a href="menu.jsp">Inicio</a>
            <a href="DashboardServlet">Dashboard</a> <!-- Ya es admin, no hace falta el if -->
            <a href="ProductoServlet">Productos</a>
            <a href="ClienteServlet">Clientes</a>
            <a href="carrito.jsp">Carrito</a>
            <a href="PedidoServlet">Pedidos</a>
            <a href="ReporteServlet"><b>Reportes</b></a>
        </nav>
        <div class="user-info">
            <span>👤 <%= vendedor.getNombre() %></span>
            <span class="badge"><%= vendedor.getRol() %></span>
            <a href="LogoutServlet" class="logout">Salir</a>
        </div>
    </header>

    <main>
        <h2>📊 Reportes del Sistema</h2>

        <%-- ESTADÍSTICAS GENERALES CENTRADAS --%>
        <% if (estadisticas != null) { %>
            <div class="modules-grid" style="margin-bottom: 30px; justify-content: center;">
                <div class="module-card" style="text-align: center; min-width: 200px;">
                    <h3>👥 Clientes</h3>
                    <p style="font-size: 2em; color: #2980b9; font-weight: bold;">
                        <%= estadisticas.get("totalClientes") %>
                    </p>
                </div>
                <div class="module-card" style="text-align: center; min-width: 200px;">
                    <h3>📦 Productos</h3>
                    <p style="font-size: 2em; color: #27ae60; font-weight: bold;">
                        <%= estadisticas.get("totalProductos") %>
                    </p>
                </div>
                <div class="module-card" style="text-align: center; min-width: 200px;">
                    <h3>🧾 Pedidos</h3>
                    <p style="font-size: 2em; color: #e67e22; font-weight: bold;">
                        <%= estadisticas.get("totalPedidos") %>
                    </p>
                </div>
                <div class="module-card" style="text-align: center; min-width: 200px;">
                    <h3>💰 Facturado</h3>
                    <p style="font-size: 1.5em; color: #c0392b; font-weight: bold;">
                        $<%= String.format("%.2f", (Double) estadisticas.get("totalFacturado")) %>
                    </p>
                </div>
            </div>
        <% } %>

        <%-- REPORTE 1: INVENTARIO --%>
        <h2>📦 Inventario por Categoría</h2>
        <div class="tabla-scroll">
            <table>
                <thead>
                    <tr><th>Categoría</th><th>Productos</th><th>Stock Total</th><th>Valor</th></tr>
                </thead>
                <tbody>
                    <% if (inventario != null) for (Map<String, Object> f : inventario) { %>
                        <tr>
                            <td><%= f.get("categoria") %></td>
                            <td><%= f.get("cantidad") %></td>
                            <td><%= f.get("stock") %></td>
                            <td>$<%= String.format("%.2f", (Double) f.get("valor")) %></td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        </div>

        <%-- REPORTE 2: MEJORES CLIENTES --%>
        <h2>⭐ Mejores Clientes (> $100)</h2>
        <!-- 🔥 CONTENEDOR CON SCROLL Y ALTURA REDUCIDA -->
        <div class="tabla-scroll" style="max-height: 300px;">
            <table>
                <thead>
                    <tr><th>Cliente</th><th>Total Gastado</th></tr>
                </thead>
                <tbody>
                    <% if (mejoresClientes != null && !mejoresClientes.isEmpty()) {
                        for (Map<String, Object> f : mejoresClientes) { %>
                        <tr>
                            <td><%= f.get("cliente") %></td>
                            <td>$<%= String.format("%.2f", (Double) f.get("total")) %></td>
                        </tr>
                    <% }} else { %>
                        <tr><td colspan="2">No hay clientes con compras mayores a $100.</td></tr>
                    <% } %>
                </tbody>
            </table>
        </div>

        <%-- REPORTE 3: VENTAS POR VENDEDOR --%>
        <h2>👔 Ventas por Vendedor</h2>
        <div class="tabla-scroll">
            <table>
                <thead>
                    <tr><th>Vendedor</th><th>Rol</th><th>Pedidos</th><th>Total</th></tr>
                </thead>
                <tbody>
                    <% if (ventasVendedor != null) for (Map<String, Object> f : ventasVendedor) { %>
                        <tr>
                            <td><%= f.get("vendedor") %></td>
                            <td><span class="badge"><%= f.get("rol") %></span></td>
                            <td><%= f.get("pedidos") %></td>
                            <td>$<%= String.format("%.2f", (Double) f.get("total")) %></td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        </div>

        <%-- REPORTE 4: MOVIMIENTOS DE INVENTARIO --%>
        <h2>📋 Últimos Movimientos de Inventario</h2>
        <div class="tabla-scroll">
            <table>
                <thead>
                    <tr><th>ID</th><th>Producto</th><th>Tipo</th><th>Cantidad</th><th>Motivo</th><th>Fecha</th></tr>
                </thead>
                <tbody>
                    <% if (movimientos != null) for (Map<String, Object> f : movimientos) { %>
                        <tr>
                            <td><%= f.get("id") %></td>
                            <td><%= f.get("producto") %></td>
                            <td><span class="badge"><%= f.get("tipo") %></span></td>
                            <td><%= f.get("cantidad") %></td>
                            <td><%= f.get("motivo") %></td>
                            <td><%= f.get("fecha") != null ? sdf.format(f.get("fecha")) : "-" %></td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        </div>

        <%-- REPORTE 5: RESEÑAS --%>
        <h2>⭐ Reseñas de Productos</h2>
        <div class="tabla-scroll">
            <table>
                <thead>
                    <tr><th>Producto</th><th>Calificación Promedio</th><th>Total Reseñas</th></tr>
                </thead>
                <tbody>
                    <% if (resenas != null && !resenas.isEmpty()) {
                        for (Map<String, Object> f : resenas) { %>
                        <tr>
                            <td><%= f.get("producto") %></td>
                            <td>
                                <b style="color: <%= ((Double) f.get("promedio")) >= 4 ? "#27ae60" : (((Double) f.get("promedio")) >= 3 ? "#f39c12" : "#c0392b") %>;">
                                    <%= String.format("%.2f", (Double) f.get("promedio")) %> ⭐
                                </b>
                            </td>
                            <td><%= f.get("total") %></td>
                        </tr>
                    <% }} else { %>
                        <tr><td colspan="3">No hay reseñas registradas.</td></tr>
                    <% } %>
                </tbody>
            </table>
        </div>

        <div style="margin-top: 30px;">
            <a href="menu.jsp" class="btn">← Volver al menú</a>
        </div>
    </main>

</body>
</html>