package com.mercadeonica.controlador;

import com.mercadeonica.dao.TarjetaDAO;
import com.mercadeonica.modelo.Cliente;
import com.mercadeonica.modelo.Tarjeta;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.List;

@WebServlet(name = "ClienteTarjetasServlet", urlPatterns = {"/ClienteTarjetasServlet"})
public class ClienteTarjetasServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========== ClienteTarjetasServlet.doGet ==========");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("cliente") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Cliente cliente = (Cliente) session.getAttribute("cliente");
        TarjetaDAO dao = new TarjetaDAO();
        String accion = request.getParameter("accion");

        // ---------- ELIMINAR ----------
        if ("eliminar".equals(accion)) {
            try {
                long numero = Long.parseLong(request.getParameter("numero"));
                String error = dao.eliminar(numero, cliente.getCustomerId());

                if (error == null) {
                    session.setAttribute("mensaje", "✅ Tarjeta eliminada correctamente.");
                } else {
                    session.setAttribute("error", "⚠️ " + error);
                }
            } catch (NumberFormatException e) {
                session.setAttribute("error", "Número de tarjeta inválido.");
            }
            response.sendRedirect("ClienteTarjetasServlet");
            return;
        }

        // ---------- LISTAR (por defecto) ----------
        List<Tarjeta> tarjetas = dao.listarPorCliente(cliente.getCustomerId());
        request.setAttribute("tarjetas", tarjetas);
        request.getRequestDispatcher("cliente-tarjetas.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========== ClienteTarjetasServlet.doPost ==========");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("cliente") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Cliente cliente = (Cliente) session.getAttribute("cliente");
        String accion = request.getParameter("accion");

        // ---------- AGREGAR ----------
        if ("agregar".equals(accion)) {
            try {
                long numero     = Long.parseLong(request.getParameter("numero").replaceAll("\\s", ""));
                String tipo     = request.getParameter("tipo");
                int mes         = Integer.parseInt(request.getParameter("mes"));
                int anio        = Integer.parseInt(request.getParameter("anio"));

                // Validaciones
                if (String.valueOf(numero).length() < 13 || String.valueOf(numero).length() > 19) {
                    session.setAttribute("error", "⚠️ El número de tarjeta debe tener entre 13 y 19 dígitos.");
                    response.sendRedirect("ClienteTarjetasServlet");
                    return;
                }

                if (mes < 1 || mes > 12) {
                    session.setAttribute("error", "⚠️ Mes inválido (1-12).");
                    response.sendRedirect("ClienteTarjetasServlet");
                    return;
                }

                java.time.LocalDate hoy = java.time.LocalDate.now();
                if (anio < hoy.getYear() || (anio == hoy.getYear() && mes < hoy.getMonthValue())) {
                    session.setAttribute("error", "⚠️ La tarjeta ya está expirada.");
                    response.sendRedirect("ClienteTarjetasServlet");
                    return;
                }

                Tarjeta t = new Tarjeta(cliente.getCustomerId(), numero, tipo, mes, anio);
                TarjetaDAO dao = new TarjetaDAO();
                String error = dao.agregar(t);

                if (error == null) {
                    session.setAttribute("mensaje", "✅ Tarjeta agregada correctamente.");
                } else {
                    session.setAttribute("error", "⚠️ " + error);
                }

            } catch (NumberFormatException e) {
                session.setAttribute("error", "⚠️ Datos inválidos.");
            }
            response.sendRedirect("ClienteTarjetasServlet");
            return;
        }

        response.sendRedirect("ClienteTarjetasServlet");
    }
}