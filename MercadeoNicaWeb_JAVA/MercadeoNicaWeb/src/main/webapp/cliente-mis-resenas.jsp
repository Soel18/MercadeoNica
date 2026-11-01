<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="com.mercadeonica.modelo.Cliente" %>
<%@ page import="com.mercadeonica.modelo.Resena" %>
<%
    Cliente cliente = (Cliente) session.getAttribute("cliente");
    if (cliente == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    List<Resena> misResenas = (List<Resena>) request.getAttribute("misResenas");
    List<Map<String, Object>> pendientes = (List<Map<String, Object>>) request.getAttribute("productosPendientes");
    Resena resenaEditar = (Resena) request.getAttribute("resenaEditar");

    String mensaje = (String) session.getAttribute("mensaje");
    String error   = (String) session.getAttribute("error");
    session.removeAttribute("mensaje");
    session.removeAttribute("error");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Mis Reseñas - MercadeoNica</title>
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
            <a href="ClienteResenasServlet"><b>Mis Reseñas</b></a>
        </nav>
        <div class="user-info">
            <span>👤 <%= cliente.getNombre() %></span>
            <span class="badge" style="background-color: #27ae60;">CLIENTE</span>
            <a href="LogoutServlet" class="logout">Salir</a>
        </div>
    </header>

    <main>
        <h2>⭐ Mis Reseñas</h2>

        <% if (mensaje != null) { %>
            <div class="ok">✅ <%= mensaje %></div>
        <% } %>

        <% if (error != null) { %>
            <div class="error">⚠️ <%= error %></div>
        <% } %>

        <%-- ============================================================ --%>
        <%-- FORMULARIO DE EDICIÓN (si hay resenaEditar)                 --%>
        <%-- ============================================================ --%>
        <% if (resenaEditar != null) { %>
            <div class="form-container" style="border: 3px solid #3498db; background: #eaf4fc; margin-bottom: 25px;">
                <h3 style="color: #2980b9; margin-top: 0;">✏️ Editar reseña de: <%= resenaEditar.getProductName() %></h3>

                <form action="ClienteResenasServlet" method="post">
                    <input type="hidden" name="accion" value="actualizar">
                    <input type="hidden" name="reviewId" value="<%= resenaEditar.getReviewId() %>">

                    <div class="form-group">
                        <label>Calificación:</label>
                        <select name="estrellas" required>
                            <% for (int i = 1; i <= 5; i++) {
                                String sel = (i == resenaEditar.getEstrellas()) ? "selected" : "";
                            %>
                                <option value="<%= i %>" <%= sel %>><%= i %> ⭐</option>
                            <% } %>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Comentario:</label>
                        <textarea name="comentario" rows="3" maxlength="200" required
                                  style="width:100%; padding:10px; border:1px solid #ccc; border-radius:4px;"><%= resenaEditar.getComentario() %></textarea>
                    </div>

                    <div style="display: flex; gap: 10px;">
                        <button type="submit" class="btn-primary" style="background-color:#3498db;">
                            💾 Guardar cambios
                        </button>
                        <a href="ClienteResenasServlet" class="btn" style="background-color: #95a5a6;">
                            Cancelar
                        </a>
                    </div>
                </form>
            </div>
        <% } %>

        <%-- ============================================================ --%>
        <%-- PRODUCTOS PENDIENTES DE RESEÑAR                              --%>
        <%-- ============================================================ --%>
        <% if (pendientes != null && !pendientes.isEmpty()) { %>
            <div class="welcome-card" style="background:#fef9e7; border-left:4px solid #f39c12;">
                <h3 style="margin-top: 0; color:#b9770e;">📝 Productos pendientes de reseñar</h3>
                <p style="color:#7f8c8d; font-size: 0.9em;">
                    Estos productos los compraste y ya se entregaron, pero aún no los has reseñado.
                </p>

                <table style="margin-top: 15px;">
                    <thead>
                        <tr>
                            <th>Producto</th>
                            <th>Tu calificación y comentario</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (Map<String, Object> p : pendientes) { %>
                            <tr>
                                <td style="vertical-align: top;"><b><%= p.get("productName") %></b></td>
                                <td>
                                    <form action="ClienteResenasServlet" method="post" style="display: flex; gap: 8px; flex-wrap: wrap; align-items: center;">
                                        <input type="hidden" name="accion" value="agregar">
                                        <input type="hidden" name="productId" value="<%= p.get("productId") %>">

                                        <select name="estrellas" required style="padding: 6px;">
                                            <option value="5">5 ⭐⭐⭐⭐⭐</option>
                                            <option value="4">4 ⭐⭐⭐⭐</option>
                                            <option value="3" selected>3 ⭐⭐⭐</option>
                                            <option value="2">2 ⭐⭐</option>
                                            <option value="1">1 ⭐</option>
                                        </select>

                                        <input type="text" name="comentario" required maxlength="200"
                                               placeholder="Escribe tu opinión (máx 200)"
                                               style="flex: 1; min-width: 250px; padding: 6px; border: 1px solid #ccc; border-radius: 4px;">

                                        <button type="submit" class="btn-primary" style="background-color: #f39c12;">
                                            ✍️ Reseñar
                                        </button>
                                    </form>
                                </td>
                            </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        <% } %>

        <%-- ============================================================ --%>
        <%-- MIS RESEÑAS (listado)                                        --%>
        <%-- ============================================================ --%>
        <h3 style="margin-top: 30px;">📋 Reseñas que he publicado</h3>

        <% if (misResenas == null || misResenas.isEmpty()) { %>
            <div class="welcome-card">
                <p>No has publicado reseñas aún.</p>
                <% if (pendientes == null || pendientes.isEmpty()) { %>
                    <p style="color:#7f8c8d; font-size:0.9em;">
                        Compra productos y cuando se entreguen podrás calificarlos. 🛍️
                    </p>
                <% } %>
            </div>
        <% } else { %>
            <table>
                <thead>
                    <tr>
                        <th>Producto</th>
                        <th>Calificación</th>
                        <th>Comentario</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (Resena r : misResenas) { %>
                        <tr>
                            <td><b><%= r.getProductName() != null ? r.getProductName() : "Producto #" + r.getProductId() %></b></td>
                            <td>
                                <b style="color: #f39c12;">
                                    <%= r.getEstrellasVisual() %><%= r.getEstrellasVaciasVisual() %>
                                </b>
                                <br>
                                <small style="color: #7f8c8d;">(<%= r.getEstrellas() %>/5)</small>
                            </td>
                            <td><%= r.getComentario() %></td>
                            <td style="white-space: nowrap;">
                                <a href="ClienteResenasServlet?accion=editar&id=<%= r.getReviewId() %>"
                                   class="btn" style="background-color: #3498db; margin-right: 5px;">
                                   ✏️ Editar
                                </a>
                                <a href="ClienteResenasServlet?accion=eliminar&id=<%= r.getReviewId() %>"
                                   class="btn-eliminar"
                                   onclick="return confirm('¿Eliminar esta reseña?')">
                                   🗑️ Eliminar
                                </a>
                            </td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        <% } %>

        <div style="margin-top: 20px;">
            <a href="cliente-menu.jsp" class="btn">← Volver a Mi Cuenta</a>
            <a href="CatalogoServlet" class="btn" style="margin-left: 10px;">Ver Catálogo</a>
        </div>
    </main>

</body>
</html>