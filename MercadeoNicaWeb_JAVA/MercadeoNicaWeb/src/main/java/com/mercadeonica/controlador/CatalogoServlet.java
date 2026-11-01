package com.mercadeonica.controlador;

import com.mercadeonica.dao.CategoriaDAO;
import com.mercadeonica.dao.ProductoDAO;
import com.mercadeonica.modelo.Producto;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;

@WebServlet(name = "CatalogoServlet", urlPatterns = {"/CatalogoServlet"})
public class CatalogoServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========== CatalogoServlet (cliente) ==========");

        String q              = request.getParameter("q");
        String catStr         = request.getParameter("categoria");
        String minStr         = request.getParameter("precioMin");
        String maxStr         = request.getParameter("precioMax");
        String soloStr        = request.getParameter("soloDisponibles");
        String orden          = request.getParameter("orden");
        String filtroResenas  = request.getParameter("resenas");   // 🔥 NUEVO

        Integer categoriaId = null;
        Double precioMin = null, precioMax = null;
        boolean soloDisponibles = "on".equals(soloStr) || "true".equals(soloStr);

        try { if (catStr != null && !catStr.isBlank()) categoriaId = Integer.parseInt(catStr); } catch (NumberFormatException ignored) {}
        try { if (minStr != null && !minStr.isBlank()) precioMin = Double.parseDouble(minStr); } catch (NumberFormatException ignored) {}
        try { if (maxStr != null && !maxStr.isBlank()) precioMax = Double.parseDouble(maxStr); } catch (NumberFormatException ignored) {}

        boolean hayFiltros = (q != null && !q.isBlank()) ||
                             categoriaId != null ||
                             precioMin != null || precioMax != null ||
                             soloDisponibles ||
                             (orden != null && !orden.isBlank()) ||
                             (filtroResenas != null && !filtroResenas.isBlank() && !"todas".equals(filtroResenas));

        ProductoDAO productoDAO = new ProductoDAO();
        CategoriaDAO categoriaDAO = new CategoriaDAO();

        List<Producto> productos;
        if (hayFiltros) {
            productos = productoDAO.buscarConFiltros(q, categoriaId, precioMin, precioMax,
                                                      soloDisponibles, orden, filtroResenas);
        } else {
            productos = productoDAO.listar();
        }

        request.setAttribute("productos", productos);
        request.setAttribute("categorias", categoriaDAO.listar());
        request.setAttribute("filtroQ", q);
        request.setAttribute("filtroCategoria", catStr);
        request.setAttribute("filtroPrecioMin", minStr);
        request.setAttribute("filtroPrecioMax", maxStr);
        request.setAttribute("filtroSoloDisponibles", soloDisponibles);
        request.setAttribute("filtroOrden", orden);
        request.setAttribute("filtroResenas", filtroResenas);   // 🔥 NUEVO

        request.getRequestDispatcher("catalogo-publico.jsp").forward(request, response);
    }
}