<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.mercadeonica.modelo.Pedido" %>
<%@ page import="com.mercadeonica.modelo.Cliente" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    Cliente cliente = (Cliente) session.getAttribute("cliente");
    if (cliente == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    List<Pedido> pedidos = (List<Pedido>) request.getAttribute("pedidos");
    String filtroActual = (String) request.getAttribute("filtroActual");

    String mensaje = (String) session.getAttribute("mensaje");
    String error   = (String) session.getAttribute("error");
    session.removeAttribute("mensaje");
    session.removeAttribute("error");

    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Mis Pedidos - MercadeoNica</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body>

    <header>
        <h1>🛒 MercadeoNica</h1>
        <nav>
            <a href="cliente-menu.jsp">Mi Cuenta</a>
            <a href="CatalogoServlet">Catálogo</a>
            <a href="ClienteCarritoServlet">Mi Carrito</a>
            <a href="ClienteMisPedidosServlet"><b>Mis Pedidos</b></a>
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
        <h2>🧾 Mis Pedidos</h2>

        <% if (mensaje != null) { %>
            <div class="ok">✅ <%= mensaje %></div>
        <% } %>

        <% if (error != null) { %>
            <div class="error">⚠️ <%= error %></div>
        <% } %>

        <div style="margin: 20px 0; display: flex; gap: 10px; flex-wrap: wrap; align-items: center;">
            <span style="font-weight: bold;">Filtrar por estado:</span>
            <a href="ClienteMisPedidosServlet" class="btn"
               style="<%= filtroActual == null ? "background-color: #2c3e50;" : "background-color: #95a5a6;" %>">
               Todos
            </a>
            <a href="ClienteMisPedidosServlet?filtro=PENDIENTE" class="btn"
               style="<%= "PENDIENTE".equals(filtroActual) ? "background-color: #f39c12;" : "background-color: #95a5a6;" %>">
               🟠 Pendientes
            </a>
            <a href="ClienteMisPedidosServlet?filtro=CONFIRMADO" class="btn"
               style="<%= "CONFIRMADO".equals(filtroActual) ? "background-color: #3498db;" : "background-color: #95a5a6;" %>">
               🔵 Confirmados
            </a>
            <a href="ClienteMisPedidosServlet?filtro=ENTREGADO" class="btn"
               style="<%= "ENTREGADO".equals(filtroActual) ? "background-color: #27ae60;" : "background-color: #95a5a6;" %>">
               🟢 Entregados
            </a>
            <a href="ClienteMisPedidosServlet?filtro=CANCELADO" class="btn"
               style="<%= "CANCELADO".equals(filtroActual) ? "background-color: #c0392b;" : "background-color: #95a5a6;" %>">
               🔴 Cancelados
            </a>
        </div>

        <% if (pedidos == null || pedidos.isEmpty()) { %>
            <div class="welcome-card">
                <p>No tienes pedidos <%= filtroActual != null ? "con estado " + filtroActual : "registrados aún" %>.</p>
                <p>Ve al <a href="CatalogoServlet">catálogo</a> y haz tu compra.</p>
            </div>
        <% } else { %>
            <div class="tabla-scroll">
                <table>
                    <thead>
                        <tr>
                            <th>#Pedido</th>
                            <th>Fecha</th>
                            <th>Estado</th>
                            <th>Total</th>
                            <th>Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (Pedido p : pedidos) {
                            String estado = p.getEstado();
                            String colorEstado =
                                "PENDIENTE".equals(estado)  ? "#f39c12" :
                                "CONFIRMADO".equals(estado) ? "#3498db" :
                                "ENTREGADO".equals(estado)  ? "#27ae60" :
                                "CANCELADO".equals(estado)  ? "#c0392b" : "#95a5a6";
                        %>
                            <tr>
                                <td><b>#<%= p.getOrderId() %></b></td>
                                <td><%= p.getFecha() != null ? sdf.format(p.getFecha()) : "-" %></td>
                                <td>
                                    <span class="badge" style="background-color: <%= colorEstado %>;">
                                        <%= estado %>
                                    </span>
                                </td>
                                <td><b style="color: #27ae60;">$<%= String.format("%.2f", p.getTotal()) %></b></td>
                                <td style="white-space: nowrap;">
                                    <a href="ClienteMisPedidosServlet?accion=verDetalle&id=<%= p.getOrderId() %>"
                                       class="btn"
                                       style="background-color: #34495e; margin-bottom: 3px; display: inline-block;">
                                       👁️ Ver detalle
                                    </a>

                                    <a href="ClienteMisPedidosServlet?accion=repetirPedido&id=<%= p.getOrderId() %>"
                                       class="btn"
                                       style="background-color: #9b59b6; margin-bottom: 3px; display: inline-block;"
                                       onclick="return confirm('¿Agregar los productos del pedido #<%= p.getOrderId() %> a tu carrito actual?')">
                                       🔁 Repetir
                                    </a>

                                    <% if ("PENDIENTE".equals(estado)) { %>
                                        <a href="ClienteMisPedidosServlet?accion=cancelarPedido&id=<%= p.getOrderId() %>"
                                           class="btn-eliminar"
                                           style="margin-bottom: 3px; display: inline-block;"
                                           onclick="return confirm('¿Cancelar el pedido #<%= p.getOrderId() %>?\n\nEl stock será devuelto automáticamente.')">
                                           ❌ Cancelar
                                        </a>
                                    <% } %>
                                </td>
                            </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        <% } %>

        <div style="margin-top: 20px;">
            <a href="cliente-menu.jsp" class="btn">← Volver a Mi Cuenta</a>
            <a href="CatalogoServlet" class="btn" style="margin-left: 10px;">Ver Catálogo</a>
        </div>
    </main>

</body>
</html>