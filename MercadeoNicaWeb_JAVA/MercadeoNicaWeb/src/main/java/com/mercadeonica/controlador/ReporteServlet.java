package com.mercadeonica.controlador;

import com.mercadeonica.dao.ReporteDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet(name = "ReporteServlet", urlPatterns = {"/ReporteServlet"})
public class ReporteServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========== ReporteServlet.doGet ==========");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("vendedor") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        ReporteDAO dao = new ReporteDAO();

        // Cargar todos los reportes
        request.setAttribute("inventario",   dao.reporteInventario());
        request.setAttribute("mejoresClientes", dao.reporteMejoresClientes(100));
        request.setAttribute("ventasVendedor", dao.reporteVentasPorVendedor());
        request.setAttribute("movimientos",  dao.reporteMovimientosInventario());
        request.setAttribute("resenas",      dao.reporteResenas());
        request.setAttribute("estadisticas", dao.estadisticasGenerales());

        request.getRequestDispatcher("reportes.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}