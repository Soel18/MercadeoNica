package com.mercadeonica.controlador;

import com.mercadeonica.dao.ResenaDAO;
import com.mercadeonica.modelo.Cliente;
import com.mercadeonica.modelo.Resena;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@WebServlet(name = "ClienteResenasServlet", urlPatterns = {"/ClienteResenasServlet"})
public class ClienteResenasServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========== ClienteResenasServlet.doGet ==========");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("cliente") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Cliente cliente = (Cliente) session.getAttribute("cliente");
        ResenaDAO dao = new ResenaDAO();
        String accion = request.getParameter("accion");

        // ---------- ELIMINAR ----------
        if ("eliminar".equals(accion)) {
            try {
                int reviewId = Integer.parseInt(request.getParameter("id"));
                String error = dao.eliminar(reviewId, cliente.getEmail(), false);
                if (error == null) {
                    session.setAttribute("mensaje", "✅ Reseña eliminada.");
                } else {
                    session.setAttribute("error", "⚠️ " + error);
                }
            } catch (NumberFormatException e) {
                session.setAttribute("error", "ID inválido.");
            }
            response.sendRedirect("ClienteResenasServlet");
            return;
        }

        // ---------- CARGAR PARA EDITAR ----------
        if ("editar".equals(accion)) {
            try {
                int reviewId = Integer.parseInt(request.getParameter("id"));
                Resena r = dao.buscarPorId(reviewId);
                if (r == null || !r.getReviewerEmail().equals(cliente.getEmail())) {
                    session.setAttribute("error", "Reseña no encontrada o no te pertenece.");
                    response.sendRedirect("ClienteResenasServlet");
                    return;
                }
                request.setAttribute("resenaEditar", r);
            } catch (NumberFormatException e) {
                session.setAttribute("error", "ID inválido.");
                response.sendRedirect("ClienteResenasServlet");
                return;
            }
        }

        // ---------- LISTAR (por defecto) ----------
        List<Resena> misResenas = dao.listarPorCliente(cliente.getEmail());
        List<Map<String, Object>> pendientes = dao.productosPendientesDeResenar(cliente.getEmail());

        request.setAttribute("misResenas", misResenas);
        request.setAttribute("productosPendientes", pendientes);
        request.getRequestDispatcher("cliente-mis-resenas.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========== ClienteResenasServlet.doPost ==========");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("cliente") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Cliente cliente = (Cliente) session.getAttribute("cliente");
        ResenaDAO dao = new ResenaDAO();
        String accion = request.getParameter("accion");

        try {
            // ---------- AGREGAR ----------
            if ("agregar".equals(accion)) {
                int productId = Integer.parseInt(request.getParameter("productId"));
                int estrellas = Integer.parseInt(request.getParameter("estrellas"));
                String comentario = request.getParameter("comentario");

                if (estrellas < 1 || estrellas > 5) {
                    session.setAttribute("error", "⚠️ Las estrellas deben estar entre 1 y 5.");
                    response.sendRedirect("ClienteResenasServlet");
                    return;
                }

                Resena r = new Resena(productId, cliente.getEmail(), estrellas, comentario);
                String error = dao.agregar(r);

                if (error == null) {
                    session.setAttribute("mensaje", "✅ ¡Gracias por tu reseña!");
                } else {
                    session.setAttribute("error", "⚠️ " + error);
                }
                response.sendRedirect("ClienteResenasServlet");
                return;
            }

            // ---------- ACTUALIZAR ----------
            if ("actualizar".equals(accion)) {
                int reviewId = Integer.parseInt(request.getParameter("reviewId"));
                int estrellas = Integer.parseInt(request.getParameter("estrellas"));
                String comentario = request.getParameter("comentario");

                if (estrellas < 1 || estrellas > 5) {
                    session.setAttribute("error", "⚠️ Las estrellas deben estar entre 1 y 5.");
                    response.sendRedirect("ClienteResenasServlet");
                    return;
                }

                String error = dao.actualizar(reviewId, cliente.getEmail(), estrellas, comentario);

                if (error == null) {
                    session.setAttribute("mensaje", "✅ Reseña actualizada.");
                } else {
                    session.setAttribute("error", "⚠️ " + error);
                }
                response.sendRedirect("ClienteResenasServlet");
                return;
            }

            // Fallback
            response.sendRedirect("ClienteResenasServlet");

        } catch (NumberFormatException e) {
            session.setAttribute("error", "⚠️ Datos inválidos.");
            response.sendRedirect("ClienteResenasServlet");
        }
    }
}