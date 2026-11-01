<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.mercadeonica.modelo.Vendedor" %>
<%
    Vendedor vendedor = (Vendedor) session.getAttribute("vendedor");
    if (vendedor == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    boolean esAdmin = vendedor.esAdmin();
    
    // 🔥 Obtener alertas de stock de la sesión
    Integer stockBajo = (Integer) session.getAttribute("stockBajo");
    Integer stockAgotado = (Integer) session.getAttribute("stockAgotado");
    if (stockBajo == null) stockBajo = 0;
    if (stockAgotado == null) stockAgotado = 0;
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Menú Principal - MercadeoNica</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body>

    <header>
        <h1>🛒 MercadeoNica</h1>
        <nav>
            <a href="menu.jsp">Inicio</a>
            <a href="ProductoServlet">Productos</a>
            <a href="ClienteServlet">Clientes</a>
            <a href="carrito.jsp">Carrito</a>
            <a href="PedidoServlet">Pedidos</a>

            <% if (esAdmin) { %>
                <a href="DashboardServlet">Dashboard</a>
                <a href="ReporteServlet">Reportes</a>
                <a href="VendedorServlet">👔 Vendedores</a>
            <% } %>
        </nav>
        <div class="user-info">
            <span>👤 <%= vendedor.getNombre() %></span>
            <span class="badge" style="background-color: <%= esAdmin ? "#e74c3c" : "#3498db" %>;">
                <%= vendedor.getRol() %>
            </span>
            <a href="LogoutServlet" class="logout">Salir</a>
        </div>
    </header>

    <main>
        <!-- 🔥 BANNER DE NOTIFICACIÓN DE STOCK -->
        <% if (stockBajo > 0 || stockAgotado > 0) { %>
            <div style="background: #fef9e7; border-left: 5px solid #f39c12; padding: 15px; border-radius: 5px; margin-bottom: 20px; color: #b9770e; font-weight: bold;">
                <h3>⚠️ Notificaciones de Inventario</h3>
                <% if (stockAgotado > 0) { %>
                    <p style="color: #c0392b; margin: 5px 0;">🔴 <b><%= stockAgotado %></b> productos están completamente <b>AGOTADOS</b>. Reabastecer urgente.</p>
                <% } %>
                <% if (stockBajo > 0) { %>
                    <p style="color: #e67e22; margin: 5px 0;">🟠 <b><%= stockBajo %></b> productos están próximos a agotarse (menos de 50 unidades).</p>
                <% } %>
                <a href="ProductoServlet" class="btn" style="background-color: #f39c12; color: white; margin-top: 10px; display: inline-block; padding: 8px 15px; text-decoration: none; border-radius: 4px;">Ver Productos</a>
            </div>
        <% } %>

        <div class="welcome-card">
            <h2>¡Bienvenido, <%= vendedor.getNombre() %>!</h2>
            <p>Has iniciado sesión como <b><%= vendedor.getRol() %></b>.</p>
            <% if (esAdmin) { %>
                <p style="color: #e74c3c; font-weight: bold;">
                    🔑 Tienes control TOTAL del sistema.
                </p>
            <% } else { %>
                <p style="color: #3498db; font-weight: bold;">
                    👤 Puedes registrar clientes, agregar productos y realizar ventas.
                </p>
            <% } %>
        </div>

        <div class="modules-grid">
            <div class="module-card">
                <h3>📦 Productos</h3>
                <p>Gestiona el catálogo</p>
                <a href="ProductoServlet" class="btn">Ir a Productos</a>
            </div>

            <div class="module-card">
                <h3>👥 Clientes</h3>
                <p>Registra clientes</p>
                <a href="ClienteServlet" class="btn">Ir a Clientes</a>
            </div>

            <div class="module-card">
                <h3>🛒 Carrito</h3>
                <p>Realiza una venta</p>
                <a href="carrito.jsp" class="btn">Ir al Carrito</a>
            </div>

            <div class="module-card">
                <h3>🧾 Pedidos</h3>
                <p>Historial de pedidos</p>
                <a href="PedidoServlet" class="btn">Ir a Pedidos</a>
            </div>

            <% if (esAdmin) { %>
                <div class="module-card" style="border: 2px solid #2980b9;">
                    <h3>📊 Dashboard <span style="color: #2980b9;">[ADMIN]</span></h3>
                    <p>Visualiza las estadísticas en tiempo real</p>
                    <a href="DashboardServlet" class="btn" style="background-color: #2980b9;">Ir al Dashboard</a>
                </div>

                <div class="module-card" style="border: 2px solid #e74c3c;">
                    <h3>📊 Reportes <span style="color: #e74c3c;">[ADMIN]</span></h3>
                    <p>Estadísticas detalladas</p>
                    <a href="ReporteServlet" class="btn" style="background-color: #e74c3c;">Ir a Reportes</a>
                </div>

                <div class="module-card" style="border: 2px solid #e74c3c;">
                    <h3>👔 Vendedores <span style="color: #e74c3c;">[ADMIN]</span></h3>
                    <p>Gestiona a tus trabajadores</p>
                    <a href="VendedorServlet" class="btn" style="background-color: #e74c3c;">Ir a Vendedores</a>
                </div>
            <% } %>
        </div>
    </main>

</body>
</html>