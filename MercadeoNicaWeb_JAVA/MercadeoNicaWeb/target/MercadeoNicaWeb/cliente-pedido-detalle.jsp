<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="com.mercadeonica.modelo.Pedido" %>
<%@ page import="com.mercadeonica.modelo.DetallePedido" %>
<%@ page import="com.mercadeonica.modelo.Cliente" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    Cliente cliente = (Cliente) session.getAttribute("cliente");
    if (cliente == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Pedido pedido = (Pedido) request.getAttribute("pedido");
    List<DetallePedido> detalles = (List<DetallePedido>) request.getAttribute("detalles");
    Map<String, Object> factura = (Map<String, Object>) request.getAttribute("factura");

    if (pedido == null) {
        response.sendRedirect("ClienteMisPedidosServlet");
        return;
    }

    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
    String estado = pedido.getEstado();
    String colorEstado =
        "PENDIENTE".equals(estado)  ? "#f39c12" :
        "CONFIRMADO".equals(estado) ? "#3498db" :
        "ENTREGADO".equals(estado)  ? "#27ae60" :
        "CANCELADO".equals(estado)  ? "#c0392b" : "#95a5a6";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Detalle del Pedido #<%= pedido.getOrderId() %> - MercadeoNica</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body>

    <header>
        <h1>🛒 MercadeoNica</h1>
        <nav>
            <a href="cliente-menu.jsp">Mi Cuenta</a>
            <a href="catalogo-publico.jsp">Catálogo</a>
            <a href="ClienteCarritoServlet">Mi Carrito</a>
            <a href="ClienteMisPedidosServlet"><b>Mis Pedidos</b></a>
        </nav>
        <div class="user-info">
            <span>👤 <%= cliente.getNombre() %></span>
            <span class="badge" style="background-color: #27ae60;">CLIENTE</span>
            <a href="LogoutServlet" class="logout">Salir</a>
        </div>
    </header>

    <main>
        <h2>🧾 Detalle del Pedido #<%= pedido.getOrderId() %></h2>

        <%-- Info del pedido --%>
        <div class="welcome-card">
            <div style="display: flex; justify-content: space-between; flex-wrap: wrap; gap: 20px;">
                <div style="flex: 1; min-width: 280px;">
                    <p><b>📅 Fecha:</b> <%= pedido.getFecha() != null ? sdf.format(pedido.getFecha()) : "-" %></p>
                    <p><b>💳 Tarjeta:</b> <%= pedido.getCcNumber() %></p>
                </div>
                <div style="flex: 1; min-width: 280px;">
                    <p>
                        <b>📌 Estado:</b>
                        <span class="badge" style="background-color: <%= colorEstado %>;">
                            <%= estado %>
                        </span>
                    </p>
                    <p style="font-size: 1.3em;">
                        <b>💰 Total:</b>
                        <span style="color: #27ae60;">$<%= String.format("%.2f", pedido.getTotal()) %></span>
                    </p>
                </div>
            </div>
        </div>

        <%-- Productos --%>
        <h3>📦 Productos del pedido</h3>
        <% if (detalles == null || detalles.isEmpty()) { %>
            <div class="welcome-card">
                <p>Este pedido no tiene productos registrados.</p>
            </div>
        <% } else { %>
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Producto</th>
                        <th>Precio Unit.</th>
                        <th>Cantidad</th>
                        <th>Subtotal</th>
                    </tr>
                </thead>
                <tbody>
                    <% int i = 1; for (DetallePedido d : detalles) { %>
                        <tr>
                            <td><%= i++ %></td>
                            <td><b><%= d.getProducto().getNombre() %></b></td>
                            <td>$<%= String.format("%.2f", d.getPrecioUnitario()) %></td>
                            <td><%= d.getCantidad() %></td>
                            <td><b>$<%= String.format("%.2f", d.getSubtotal()) %></b></td>
                        </tr>
                    <% } %>
                </tbody>
                <tfoot>
                    <tr>
                        <td colspan="4" style="text-align: right; font-weight: bold;">TOTAL:</td>
                        <td style="font-weight: bold; color: #27ae60; font-size: 1.1em;">
                            $<%= String.format("%.2f", pedido.getTotal()) %>
                        </td>
                    </tr>
                </tfoot>
            </table>
        <% } %>

        <%-- 🔥 Factura (si existe) --%>
        <% if (factura != null) { %>
            <h3 style="margin-top: 30px;">📄 Factura</h3>
            <div class="welcome-card" style="background: #fef9e7; border-left: 4px solid #f39c12;">
                <p><b>N° Factura:</b> <%= factura.get("invoiceid") %></p>
                <p><b>Monto:</b> <span style="color: #27ae60; font-weight: bold;">$<%= String.format("%.2f", (Double) factura.get("amount")) %></span></p>
                <p><b>Tarjeta:</b> ****<%= String.valueOf(factura.get("creditcard")).substring(Math.max(0, String.valueOf(factura.get("creditcard")).length() - 4)) %></p>
                <% if (factura.get("creditcard_type") != null) { %>
                    <p><b>Tipo:</b> <%= factura.get("creditcard_type") %></p>
                <% } %>
            </div>
        <% } %>

        <%-- Acciones --%>
        <div style="margin-top: 30px; display: flex; gap: 10px; flex-wrap: wrap;">
            <a href="ClienteMisPedidosServlet" class="btn">← Volver a Mis Pedidos</a>

            <% if ("PENDIENTE".equals(estado)) { %>
                <a href="ClienteMisPedidosServlet?accion=cancelarPedido&id=<%= pedido.getOrderId() %>"
                   class="btn-eliminar"
                   onclick="return confirm('¿Cancelar el pedido #<%= pedido.getOrderId() %>?\n\nEl stock será devuelto automáticamente.')">
                   ❌ Cancelar pedido
                </a>
            <% } %>

            <a href="ClienteMisPedidosServlet?accion=repetirPedido&id=<%= pedido.getOrderId() %>"
               class="btn"
               style="background-color: #9b59b6;"
               onclick="return confirm('¿Agregar los productos de este pedido a tu carrito actual?')">
               🔁 Repetir compra
            </a>
        </div>
    </main>

</body>
</html>