package com.mercadeonica.controlador;

import com.mercadeonica.dao.DashboardDAO;
import com.mercadeonica.modelo.Vendedor;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;

@WebServlet(name = "DashboardServlet", urlPatterns = {"/DashboardServlet"})
public class DashboardServlet extends HttpServlet {

    private static final int LIMITE_BAJO_STOCK = 50;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        Vendedor vendedor = (Vendedor) (session != null ? session.getAttribute("vendedor") : null);
        if (vendedor == null || !vendedor.esAdmin()) {
            response.sendRedirect("menu.jsp");
            return;
        }

        String filtro = request.getParameter("filtroFecha");
        if (filtro == null) filtro = "todos";

        LocalDate hoy = LocalDate.now();
        LocalDate inicio = LocalDate.of(2000, 1, 1);
        LocalDate fin = hoy;
        LocalDate inicioAnterior = LocalDate.of(2000, 1, 1);
        LocalDate finAnterior = LocalDate.of(2000, 1, 1);

        if ("personalizado".equals(filtro)) {
            String fIni = request.getParameter("fechaInicio");
            String fFin = request.getParameter("fechaFin");
            try {
                inicio = LocalDate.parse(fIni);
                fin = LocalDate.parse(fFin);
                long dias = java.time.temporal.ChronoUnit.DAYS.between(inicio, fin);
                finAnterior = inicio.minusDays(1);
                inicioAnterior = finAnterior.minusDays(dias);
            } catch (Exception e) {
                inicio = LocalDate.of(2000, 1, 1);
                fin = hoy;
                inicioAnterior = LocalDate.of(2000, 1, 1);
                finAnterior = LocalDate.of(2000, 1, 1);
                filtro = "todos";
            }
        } else if ("ultimos_3_meses".equals(filtro)) {
            fin = hoy;
            inicio = hoy.minusMonths(3).withDayOfMonth(1);
            inicioAnterior = inicio.minusMonths(3);
            finAnterior = inicio.minusDays(1);
        } else if ("este_anio".equals(filtro)) {
            fin = hoy;
            inicio = hoy.withDayOfYear(1);
            inicioAnterior = inicio.minusYears(1);
            finAnterior = hoy.minusYears(1);
        } else if ("mes_actual".equals(filtro)) {
            fin = hoy;
            inicio = hoy.withDayOfMonth(1);
            inicioAnterior = inicio.minusMonths(1);
            finAnterior = inicio.minusDays(1);
        }

        java.sql.Date sqlInicio = java.sql.Date.valueOf(inicio);
        java.sql.Date sqlFin = java.sql.Date.valueOf(fin);
        java.sql.Date sqlInicioAnterior = java.sql.Date.valueOf(inicioAnterior);
        java.sql.Date sqlFinAnterior = java.sql.Date.valueOf(finAnterior);

        DashboardDAO dao = new DashboardDAO();

        // Flujo normal
        double totalFacturado, ticketPromedio;
        List<Object[]> ventas, pedidos, productos, clientes, vendedores;

        if ("todos".equals(filtro)) {
            totalFacturado = dao.obtenerTotalFacturadoTodos();
            ticketPromedio = dao.obtenerTicketPromedioTodos();
            ventas = dao.obtenerVentasPorMesTodos();
            pedidos = dao.obtenerPedidosPorEstadoTodos();
            productos = dao.obtenerTopProductosTodos();
            clientes = dao.obtenerTopClientesTodos();
            vendedores = dao.obtenerVentasPorVendedorTodos();
        } else {
            totalFacturado = dao.obtenerTotalFacturado(sqlInicio, sqlFin);
            ticketPromedio = dao.obtenerTicketPromedio(sqlInicio, sqlFin);
            ventas = dao.obtenerVentasPorMes(sqlInicio, sqlFin);
            pedidos = dao.obtenerPedidosPorEstado(sqlInicio, sqlFin);
            productos = dao.obtenerTopProductos(sqlInicio, sqlFin);
            clientes = dao.obtenerTopClientes(sqlInicio, sqlFin);
            vendedores = dao.obtenerVentasPorVendedor(sqlInicio, sqlFin);
        }

        // Enviar datos nuevos a la vista
        request.setAttribute("ventasPorHora", dao.obtenerVentasPorHora(sqlInicio, sqlFin));
        request.setAttribute("ventasPorCategoriaProd", dao.obtenerVentasPorCategoriaProducto(sqlInicio, sqlFin));
        request.setAttribute("metodosPago", dao.obtenerMetodosDePago(sqlInicio, sqlFin));
        request.setAttribute("topProductosCalificados", dao.obtenerTopProductosCalificados());
        request.setAttribute("ventasPeriodoAnterior", dao.obtenerVentasPorMesAnterior(sqlInicioAnterior, sqlFinAnterior));

        request.setAttribute("totalFacturado", totalFacturado);
        request.setAttribute("totalFacturadoAnterior", dao.obtenerTotalFacturado(sqlInicioAnterior, sqlFinAnterior));
        request.setAttribute("ticketPromedio", ticketPromedio);
        request.setAttribute("totalClientes", dao.obtenerTotalClientes());
        request.setAttribute("pedidosPendientes", dao.obtenerPedidosPendientes());
        request.setAttribute("productosBajoStock", dao.obtenerProductosBajoStock());
        request.setAttribute("ventasPorMes", ventas);
        request.setAttribute("pedidosPorEstado", pedidos);
        request.setAttribute("topProductos", productos);
        request.setAttribute("topClientes", clientes);
        request.setAttribute("ventasVendedor", vendedores);
        request.setAttribute("clientesPorCategoria", dao.obtenerClientesPorCategoria());
        request.setAttribute("listaBajoStock", dao.obtenerListaBajoStock());
        request.setAttribute("filtroFecha", filtro);
        request.setAttribute("fechaInicio", inicio.toString());
        request.setAttribute("fechaFin", fin.toString());
        request.setAttribute("limiteBajoStock", LIMITE_BAJO_STOCK);

        request.getRequestDispatcher("dashboard.jsp").forward(request, response);
    }
}