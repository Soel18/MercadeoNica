<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.mercadeonica.modelo.*" %>
<%
    Cliente cliente = (Cliente) session.getAttribute("cliente");
    if (cliente == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Carrito carrito = (Carrito) session.getAttribute("carritoCliente");
    if (carrito == null) {
        carrito = new Carrito();
        session.setAttribute("carritoCliente", carrito);
    }

    String mensaje = (String) session.getAttribute("mensaje");
    String error   = (String) session.getAttribute("error");
    session.removeAttribute("mensaje");
    session.removeAttribute("error");

    double subtotal   = carrito.calcularTotal();
    double descuento  = cliente.getDescuento();
    double montoDesc  = subtotal * (descuento / 100.0);
    double totalFinal = subtotal - montoDesc;
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Mi Carrito - MercadeoNica</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body>

    <header>
        <h1>🛒 MercadeoNica</h1>
        <nav>
            <a href="cliente-menu.jsp">Mi Cuenta</a>
            <!-- 🔥 CORREGIDO: Ahora apunta al Servlet -->
            <a href="CatalogoServlet">Catálogo</a>
            <a href="ClienteCarritoServlet"><b>Mi Carrito</b></a>
            <a href="ClienteMisPedidosServlet">Mis Pedidos</a>
        </nav>
        <div class="user-info">
            <span>👤 <%= cliente.getNombre() %></span>
            <span class="badge" style="background-color: #27ae60;">CLIENTE</span>
            <a href="LogoutServlet" class="logout">Salir</a>
        </div>
    </header>

    <main>
        <h2>🛒 Mi Carrito de Compras</h2>

        <% if (mensaje != null) { %>
            <div class="ok">✅ <%= mensaje %></div>
        <% } %>

        <% if (error != null) { %>
            <div class="error">⚠️ <%= error %></div>
        <% } %>

        <%-- Info de categoría del cliente --%>
        <div class="welcome-card" style="background:#eafaf1; border-left:4px solid #27ae60; padding:12px 20px; margin-bottom:15px;">
            <p style="margin:0; color:#1e8449;">
                🏷️ Tu categoría: <b><%= cliente.getCategoriaNombre() != null ? cliente.getCategoriaNombre() : "Regular" %></b>
                <% if (descuento > 0) { %>
                    | 💰 Descuento aplicado: <b><%= (int) descuento %>%</b>
                <% } else { %>
                    | <span style="color:#7f8c8d;">Sin descuento aún</span>
                <% } %>
            </p>
        </div>

        <% if (carrito.estaVacio()) { %>
            <div class="welcome-card">
                <p>Tu carrito está vacío.</p>
                <!-- 🔥 CORREGIDO -->
                <p>Ve al <a href="CatalogoServlet">catálogo</a> para agregar productos.</p>
            </div>
        <% } else { %>
            <table>
                <thead>
                    <tr>
                        <th>Producto</th>
                        <th>Precio Unit.</th>
                        <th>Cantidad</th>
                        <th>Subtotal</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (NodoCarrito n : carrito.listar()) { %>
                        <tr>
                            <td><%= n.getProducto().getNombre() %></td>
                            <td>$<%= String.format("%.2f", n.getProducto().getPrecioUnitario()) %></td>
                            <td><%= n.getCantidad() %></td>
                            <td>$<%= String.format("%.2f", n.getSubtotal()) %></td>
                            <td>
                                <a href="ClienteCarritoServlet?accion=eliminar&productId=<%= n.getProducto().getProductId() %>"
                                   class="btn-eliminar"
                                   onclick="return confirm('¿Eliminar este producto?')">Eliminar</a>
                            </td>
                        </tr>
                    <% } %>
                </tbody>
                <tfoot>
                    <tr>
                        <td colspan="3" style="text-align:right;">Subtotal:</td>
                        <td colspan="2" style="text-align:right;">
                            $<%= String.format("%.2f", subtotal) %>
                        </td>
                    </tr>

                    <% if (descuento > 0) { %>
                        <tr>
                            <td colspan="3" style="text-align:right; color: #e67e22; font-weight: bold;">
                                Descuento (<%= (int) descuento %>%):
                            </td>
                            <td colspan="2" style="text-align:right; color: #e67e22;">
                                -$<%= String.format("%.2f", montoDesc) %>
                            </td>
                        </tr>
                    <% } %>

                    <tr style="background: #f8f9fa;">
                        <td colspan="3" style="text-align:right; font-weight:bold; font-size: 1.2em;">TOTAL:</td>
                        <td colspan="2" style="text-align:right; font-weight:bold; font-size: 1.2em; color:#27ae60;">
                            $<%= String.format("%.2f", totalFinal) %>
                        </td>
                    </tr>
                </tfoot>
            </table>

            <div style="margin-top: 20px; display:flex; gap: 10px; flex-wrap: wrap;">
                <!-- 🔥 CORREGIDO -->
                <a href="CatalogoServlet" class="btn">← Seguir comprando</a>
                <a href="ClienteCarritoServlet?accion=vaciar" class="btn-eliminar"
                   onclick="return confirm('¿Vaciar el carrito?')">🗑️ Vaciar carrito</a>
                <a href="cliente-confirmar-pedido.jsp" class="btn-primary" style="background-color: #27ae60;">
                    ✅ Confirmar pedido →
                </a>
            </div>
        <% } %>
    </main>

</body>
</html>