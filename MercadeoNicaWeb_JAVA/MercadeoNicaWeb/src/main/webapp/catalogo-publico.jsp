<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="com.mercadeonica.modelo.Producto" %>
<%@ page import="com.mercadeonica.modelo.Categoria" %>
<%@ page import="com.mercadeonica.modelo.Cliente" %>
<%
    List<Producto> productos   = (List<Producto>) request.getAttribute("productos");
    List<Categoria> categorias = (List<Categoria>) request.getAttribute("categorias");
    Cliente cliente = (Cliente) session.getAttribute("cliente");
    boolean logueado = (cliente != null);

    String filtroQ         = (String) request.getAttribute("filtroQ");
    String filtroCategoria = (String) request.getAttribute("filtroCategoria");
    String filtroMin       = (String) request.getAttribute("filtroPrecioMin");
    String filtroMax       = (String) request.getAttribute("filtroPrecioMax");
    Boolean filtroSoloDisp = (Boolean) request.getAttribute("filtroSoloDisponibles");
    String filtroOrden     = (String) request.getAttribute("filtroOrden");
    String filtroResenas   = (String) request.getAttribute("filtroResenas");
    if (filtroQ == null) filtroQ = "";
    if (filtroCategoria == null) filtroCategoria = "";
    if (filtroMin == null) filtroMin = "";
    if (filtroMax == null) filtroMax = "";
    if (filtroSoloDisp == null) filtroSoloDisp = false;
    if (filtroOrden == null) filtroOrden = "reciente";
    if (filtroResenas == null) filtroResenas = "todas";

    int totalProductos = productos != null ? productos.size() : 0;

    Map<Integer, Double> promedios = new com.mercadeonica.dao.ResenaDAO().obtenerPromedios();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Catálogo - MercadeoNica</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body>

    <header>
        <h1>🛒 MercadeoNica</h1>
        <nav>
            <% if (logueado) { %>
                <a href="cliente-menu.jsp">Mi Cuenta</a>
                <a href="CatalogoServlet"><b>Catálogo</b></a>
                <a href="ClienteCarritoServlet">Mi Carrito</a>
                <a href="ClienteMisPedidosServlet">Mis Pedidos</a>
                <a href="ClienteTarjetasServlet">Mis Tarjetas</a>
                <a href="ClienteResenasServlet">Mis Reseñas</a>
            <% } else { %>
                <a href="login.jsp">Inicio</a>
                <a href="CatalogoServlet"><b>Catálogo</b></a>
                <a href="login.jsp">Iniciar Sesión</a>
            <% } %>
        </nav>
        <div class="user-info">
            <% if (logueado) { %>
                <span>👤 <%= cliente.getNombre() %></span>
                <span class="badge" style="background-color: #27ae60;">CLIENTE</span>
                <a href="LogoutServlet" class="logout">Salir</a>
            <% } else { %>
                <a href="login.jsp" class="btn">Iniciar Sesión</a>
            <% } %>
        </div>
    </header>

    <main>
        <h2>🛍️ Catálogo de Productos</h2>

        <% if (!logueado) { %>
            <div class="welcome-card" style="background: #eafaf1; border-left: 4px solid #27ae60;">
                <p style="color: #27ae60;">
                    💡 <b>¿Quieres comprar?</b>
                    <a href="login.jsp">Inicia sesión</a> o
                    <a href="cliente-registro.jsp">regístrate gratis</a>
                    para agregar productos al carrito.
                </p>
            </div>
        <% } %>

        <%-- BARRA DE BÚSQUEDA Y FILTROS --%>
        <div class="form-container" style="background:#f8f9fa; margin-bottom:20px;">
            <form action="CatalogoServlet" method="get">
                
                <%-- FILA 1: BUSCADOR Y CATEGORÍA --%>
                <div style="display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 12px;">
                    <div style="flex: 2; min-width: 200px;">
                        <label style="font-weight: 500;">🔍 Buscar:</label>
                        <input type="text" name="q" value="<%= filtroQ %>"
                               placeholder="Nombre del producto..."
                               style="width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px;">
                    </div>

                    <div style="flex: 1; min-width: 180px;">
                        <label style="font-weight: 500;">🏷️ Categoría:</label>
                        <select name="categoria" style="width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px;">
                            <option value="">Todas las categorías</option>
                            <% if (categorias != null) for (Categoria c : categorias) {
                                String sel = String.valueOf(c.getCategoryId()).equals(filtroCategoria) ? "selected" : "";
                            %>
                                <option value="<%= c.getCategoryId() %>" <%= sel %>><%= c.getNombre() %></option>
                            <% } %>
                        </select>
                    </div>
                </div>

                <%-- FILA 2: PRECIOS, RESEÑAS, ORDEN Y STOCK --%>
                <div style="display: flex; gap: 10px; flex-wrap: wrap; align-items: end;">
                    <div style="min-width: 120px;">
                        <label style="font-weight: 500;">💵 Precio mín:</label>
                        <input type="number" name="precioMin" step="0.01" min="0"
                               value="<%= filtroMin %>" placeholder="$0"
                               style="width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px;">
                    </div>

                    <div style="min-width: 120px;">
                        <label style="font-weight: 500;">💵 Precio máx:</label>
                        <input type="number" name="precioMax" step="0.01" min="0"
                               value="<%= filtroMax %>" placeholder="$9999"
                               style="width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px;">
                    </div>

                    <div style="min-width: 180px;">
                        <label style="font-weight: 500;">⭐ Filtrar por reseñas:</label>
                        <select name="resenas" style="width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px;">
                            <option value="todas" <%= "todas".equals(filtroResenas) ? "selected" : "" %>>Todas</option>
                            <option value="5"     <%= "5".equals(filtroResenas)     ? "selected" : "" %>>⭐⭐⭐⭐⭐ Solo 5 estrellas</option>
                            <option value="4"     <%= "4".equals(filtroResenas)     ? "selected" : "" %>>⭐⭐⭐⭐ 4+ estrellas</option>
                            <option value="3"     <%= "3".equals(filtroResenas)     ? "selected" : "" %>>⭐⭐⭐ 3+ estrellas</option>
                            <option value="2"     <%= "2".equals(filtroResenas)     ? "selected" : "" %>>⭐⭐ 2+ estrellas</option>
                            <option value="sin"   <%= "sin".equals(filtroResenas)   ? "selected" : "" %>>❌ Sin reseñas</option>
                        </select>
                    </div>

                    <div style="min-width: 200px;">
                        <label style="font-weight: 500;">📊 Ordenar por:</label>
                        <select name="orden" style="width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px;">
                            <option value="reciente"          <%= "reciente".equals(filtroOrden)          ? "selected" : "" %>>Más reciente</option>
                            <option value="nombre"            <%= "nombre".equals(filtroOrden)            ? "selected" : "" %>>Nombre (A-Z)</option>
                            <option value="precio_asc"        <%= "precio_asc".equals(filtroOrden)        ? "selected" : "" %>>Precio: menor a mayor</option>
                            <option value="precio_desc"       <%= "precio_desc".equals(filtroOrden)       ? "selected" : "" %>>Precio: mayor a menor</option>
                            <option value="mejor_calificado"  <%= "mejor_calificado".equals(filtroOrden)  ? "selected" : "" %>>⭐ Mejor calificados</option>
                            <option value="peor_calificado"   <%= "peor_calificado".equals(filtroOrden)   ? "selected" : "" %>>⭐ Peor calificados</option>
                        </select>
                    </div>

                    <div style="padding-bottom: 8px;">
                        <label style="cursor:pointer;">
                            <input type="checkbox" name="soloDisponibles" <%= filtroSoloDisp ? "checked" : "" %>>
                            Solo con stock
                        </label>
                    </div>
                </div>

                <%-- FILA 3: BOTONES --%>
                <div style="margin-top: 15px; display: flex; gap: 10px;">
                    <button type="submit" class="btn-primary">🔍 Buscar</button>
                    <a href="CatalogoServlet" class="btn" style="background-color: #95a5a6; text-decoration: none; padding: 10px 20px;">🔄 Limpiar</a>
                </div>
            </form>
        </div>

        <p style="color: #7f8c8d; margin-bottom: 10px;">
            📦 <b><%= totalProductos %></b> producto(s) encontrado(s)
        </p>

        <div class="tabla-scroll">
            <table>
                <thead>
                    <tr>
                        <th>Producto</th>
                        <th>Categoría</th>
                        <th>Precio</th>
                        <th>⭐ Reseñas</th>
                        <th>Disponible</th>
                        <% if (logueado) { %>
                            <th>Agregar al Carrito</th>
                        <% } %>
                    </tr>
                </thead>
                <tbody>
                    <% if (productos != null && !productos.isEmpty()) {
                        for (Producto p : productos) { %>
                        <tr>
                            <td><b><%= p.getNombre() %></b></td>
                            <td><%= p.getCategoriaNombre() != null ? p.getCategoriaNombre() : "-" %></td>
                            <td>$<%= String.format("%.2f", p.getPrecioUnitario()) %></td>

                            <td>
                                <% Double prom = promedios.get(p.getProductId());
                                   if (prom != null && prom > 0) { %>
                                    <b style="color: #f39c12;"><%= String.format("%.1f", prom) %> ⭐</b>
                                <% } else { %>
                                    <span style="color: #999; font-size: 0.85em;">Sin reseñas</span>
                                <% } %>
                            </td>

                            <td>
                                <% if (p.getCantidadDisponible() > 0) { %>
                                    <span style="color: #27ae60;">✅ <%= p.getCantidadDisponible() %></span>
                                <% } else { %>
                                    <span style="color: #c0392b;">❌ Agotado</span>
                                <% } %>
                            </td>
                            <% if (logueado) { %>
                                <td>
                                    <% if (p.getCantidadDisponible() > 0) { %>
                                        <form action="ClienteCarritoServlet" method="post" style="display:flex; gap:5px; align-items:center;">
                                            <input type="hidden" name="accion" value="agregar">
                                            <input type="hidden" name="productId" value="<%= p.getProductId() %>">
                                            <input type="number" name="cantidad" value="1" min="1" max="<%= p.getCantidadDisponible() %>" style="width:60px; padding:5px;">
                                            <button type="submit" class="btn">Agregar</button>
                                        </form>
                                    <% } else { %>
                                        <span style="color: #999;">No disponible</span>
                                    <% } %>
                                </td>
                            <% } %>
                        </tr>
                    <% }} else { %>
                        <tr><td colspan="<%= logueado ? 6 : 5 %>" style="text-align:center; color:#7f8c8d; padding:20px;">
                            No se encontraron productos con esos filtros.
                        </td></tr>
                    <% } %>
                </tbody>
            </table>
        </div>

        <% if (!logueado) { %>
            <div style="text-align: center; margin-top: 30px;">
                <a href="cliente-registro.jsp" class="btn-primary" style="font-size: 1.1em; padding: 15px 30px;">
                    🚀 Crear cuenta gratis
                </a>
            </div>
        <% } %>
    </main>

</body>
</html>