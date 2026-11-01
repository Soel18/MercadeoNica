<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.mercadeonica.modelo.Cliente" %>
<%
    Cliente cliente = (Cliente) session.getAttribute("cliente");
    if (cliente == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Mi Cuenta - MercadeoNica</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body>

    <header>
        <h1>🛒 MercadeoNica</h1>
        <nav>
            <a href="cliente-menu.jsp">Mi Cuenta</a>
            <a href="CatalogoServlet">Catálogo</a>
            <a href="ClienteCarritoServlet">Mi Carrito</a>
            <a href="ClienteMisPedidosServlet">Mis Pedidos</a>
            <a href="ClienteTarjetasServlet">Mis Tarjetas</a>
            <a href="ClienteResenasServlet">Mis Reseñas</a>
        </nav>
        <div class="user-info">
            <span>👤 <%= cliente.getNombre() %></span>
            <span class="badge" style="background-color: #27ae60;">CLIENTE</span>
            <a href="LogoutServlet" class="logout">Salir</a>
        </div>
    </header>

    <main>
        <div class="welcome-card">
            <h2>¡Bienvenido, <%= cliente.getNombre() %>!</h2>
            <p>Has iniciado sesión como <b>CLIENTE</b>.</p>
            <p>Desde aquí puedes comprar productos y ver tus pedidos.</p>

            <% if (cliente.getTelefono() != null && !cliente.getTelefono().isEmpty()) { %>
                <p>📱 Teléfono: <b><%= cliente.getTelefono() %></b></p>
            <% } %>
        </div>

        <div class="modules-grid">
            <div class="module-card">
                <h3>🛍️ Ver Catálogo</h3>
                <p>Explora todos los productos disponibles</p>
                <a href="CatalogoServlet" class="btn">Ver Productos</a>
            </div>

            <div class="module-card">
                <h3>🛒 Mi Carrito</h3>
                <p>Revisa los productos que has agregado</p>
                <a href="ClienteCarritoServlet" class="btn">Ir al Carrito</a>
            </div>

            <div class="module-card">
                <h3>🧾 Mis Pedidos</h3>
                <p>Consulta el estado de tus compras</p>
                <a href="ClienteMisPedidosServlet" class="btn">Ver Mis Pedidos</a>
            </div>

            <div class="module-card">
                <h3>💳 Mis Tarjetas</h3>
                <p>Administra tus tarjetas de crédito</p>
                <a href="ClienteTarjetasServlet" class="btn">Ver Tarjetas</a>
            </div>

            <%-- 🔥 NUEVO MÓDULO: RESEÑAS --%>
            <div class="module-card">
                <h3>⭐ Mis Reseñas</h3>
                <p>Califica los productos que has comprado</p>
                <a href="ClienteResenasServlet" class="btn">Ver Reseñas</a>
            </div>
        </div>
    </main>

</body>
</html>