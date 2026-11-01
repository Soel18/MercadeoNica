<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.mercadeonica.modelo.Cliente" %>
<%@ page import="com.mercadeonica.modelo.Tarjeta" %>
<%
    Cliente cliente = (Cliente) session.getAttribute("cliente");
    if (cliente == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    List<Tarjeta> tarjetas = (List<Tarjeta>) request.getAttribute("tarjetas");
    String mensaje = (String) session.getAttribute("mensaje");
    String error   = (String) session.getAttribute("error");
    session.removeAttribute("mensaje");
    session.removeAttribute("error");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Mis Tarjetas - MercadeoNica</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body>

    <header>
        <h1>🛒 MercadeoNica</h1>
        <nav>
            <a href="cliente-menu.jsp">Mi Cuenta</a>
            <a href="catalogo-publico.jsp">Catálogo</a>
            <a href="ClienteCarritoServlet">Mi Carrito</a>
            <a href="ClienteMisPedidosServlet">Mis Pedidos</a>
            <a href="ClienteTarjetasServlet"><b>Mis Tarjetas</b></a>
        </nav>
        <div class="user-info">
            <span>👤 <%= cliente.getNombre() %></span>
            <span class="badge" style="background-color: #27ae60;">CLIENTE</span>
            <a href="LogoutServlet" class="logout">Salir</a>
        </div>
    </header>

    <main>
        <h2>💳 Mis Tarjetas de Crédito</h2>

        <% if (mensaje != null) { %>
            <div class="ok">✅ <%= mensaje %></div>
        <% } %>

        <% if (error != null) { %>
            <div class="error">⚠️ <%= error %></div>
        <% } %>

        <% if (tarjetas == null || tarjetas.isEmpty()) { %>
            <div class="welcome-card">
                <p>Aún no tienes tarjetas registradas.</p>
                <p>Agrega una abajo para poder comprar más rápido.</p>
            </div>
        <% } else { %>
            <table>
                <thead>
                    <tr>
                        <th>Tipo</th>
                        <th>Número</th>
                        <th>Expiración</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (Tarjeta t : tarjetas) {
                        boolean expirada = t.isExpirada();
                    %>
                        <tr>
                            <td><b><%= t.getTipo() %></b></td>
                            <td><%= t.getNumeroEnmascarado() %></td>
                            <td><%= t.getFechaExpiracion() %></td>
                            <td>
                                <% if (expirada) { %>
                                    <span style="color: #c0392b;">❌ Expirada</span>
                                <% } else { %>
                                    <span style="color: #27ae60;">✅ Activa</span>
                                <% } %>
                            </td>
                            <td>
                                <a href="ClienteTarjetasServlet?accion=eliminar&numero=<%= t.getNumero() %>"
                                   class="btn-eliminar"
                                   onclick="return confirm('¿Eliminar esta tarjeta?\n\nSi tiene facturas asociadas, no se podrá eliminar.')">
                                   🗑️ Eliminar
                                </a>
                            </td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        <% } %>

        <h2 style="margin-top: 30px;">➕ Agregar tarjeta nueva</h2>
        <div class="form-container">
            <form action="ClienteTarjetasServlet" method="post">
                <input type="hidden" name="accion" value="agregar">

                <div class="form-group">
                    <label>Número de tarjeta:</label>
                    <input type="text" name="numero" required
                           pattern="[0-9]{13,19}"
                           placeholder="1234567890123456"
                           title="Solo números, entre 13 y 19 dígitos"
                           maxlength="19">
                </div>

                <div class="form-group">
                    <label>Tipo de tarjeta:</label>
                    <select name="tipo" required>
                        <option value="">-- Selecciona --</option>
                        <option value="VISA">VISA</option>
                        <option value="MC">MasterCard</option>
                        <option value="AMEX">American Express</option>
                        <option value="Discover">Discover</option>
                    </select>
                </div>

                <div class="form-group">
                    <label>Mes de expiración (1-12):</label>
                    <input type="number" name="mes" min="1" max="12" required>
                </div>

                <div class="form-group">
                    <label>Año de expiración (ej: 2027):</label>
                    <input type="number" name="anio" min="2026" max="2100" required>
                </div>

                <button type="submit" class="btn-primary">💾 Agregar tarjeta</button>
            </form>
        </div>

        <div style="margin-top: 20px;">
            <a href="cliente-menu.jsp" class="btn">← Volver a Mi Cuenta</a>
        </div>
    </main>

</body>
</html>