import { useState, useEffect } from "react";
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  CircularProgress,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TableContainer,
  Button,
} from "@mui/material";
import {
  Users,
  Store,
  CalendarCheck,
  TrendingUp,
  Clock,
  ArrowUpRight,
  ShieldAlert,
  DollarSign,
  ShoppingBag,
  CheckCircle,
  Bell,
} from "lucide-react";
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  Filler,
} from "chart.js";
import { Line, Bar } from "react-chartjs-2";
import { useNavigate } from "react-router-dom";
import api from "../utils/api";

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  Filler,
);

const StatCard = ({ title, value, icon, color, subtitle }) => (
  <Card sx={{ height: "100%", position: "relative", overflow: "hidden" }}>
    <CardContent>
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "flex-start",
        }}
      >
        <Box>
          <Typography
            color="text.secondary"
            variant="body2"
            fontWeight={600}
            gutterBottom
          >
            {title}
          </Typography>
          <Typography variant="h4" fontWeight={700}>
            {value}
          </Typography>
          {subtitle && (
            <Typography
              variant="caption"
              color="text.secondary"
              sx={{ mt: 0.5, display: "block" }}
            >
              {subtitle}
            </Typography>
          )}
        </Box>
        <Box
          sx={{
            p: 1.5,
            borderRadius: 3,
            bgcolor: `${color}.light`,
            color: `${color}.main`,
            opacity: 0.85,
          }}
        >
          {icon}
        </Box>
      </Box>
    </CardContent>
    <Box
      sx={{
        position: "absolute",
        bottom: -20,
        right: -20,
        width: 100,
        height: 100,
        borderRadius: "50%",
        bgcolor: `${color}.main`,
        opacity: 0.04,
      }}
    />
  </Card>
);

const statusColors = {
  Pending: "warning",
  Confirmed: "info",
  Preparing: "info",
  Delivered: "success",
  Completed: "success",
  Cancelled: "error",
  Rejected: "error",
};

const Dashboard = () => {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await api.get("/admin/dashboard-stats");
      console.log("Dashboard stats response:", response.data);
      if (response.data?.success === true) {
        setStats(response.data);
      } else {
        setError("Invalid response format from server");
      }
    } catch (err) {
      console.error(
        "Failed to fetch stats:",
        err.response?.data || err.message,
      );
      setError(
        err.response?.data?.message ||
          "Failed to load dashboard data. Please try again.",
      );
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Box
        sx={{
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          height: "80vh",
        }}
      >
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Box
        sx={{
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          height: "80vh",
          flexDirection: "column",
          gap: 2,
        }}
      >
        <Typography color="error">{error}</Typography>
        <Chip label="Retry" onClick={fetchStats} color="primary" clickable />
      </Box>
    );
  }

  const userGrowthData = {
    labels: stats?.charts?.userGrowth?.map((d) => d._id) || [],
    datasets: [
      {
        fill: true,
        label: "New Users",
        data: stats?.charts?.userGrowth?.map((d) => d.count) || [],
        borderColor: "#1E293B",
        backgroundColor: "rgba(30, 41, 59, 0.1)",
        tension: 0.4,
        pointRadius: 3,
        pointBackgroundColor: "#1E293B",
      },
    ],
  };

  const bookingGrowthData = {
    labels: stats?.charts?.bookingGrowth?.map((d) => d._id) || [],
    datasets: [
      {
        label: "Bookings",
        data: stats?.charts?.bookingGrowth?.map((d) => d.count) || [],
        backgroundColor: "rgba(142, 45, 226, 0.7)",
        borderRadius: 6,
        borderSkipped: false,
      },
    ],
  };

  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
      tooltip: {
        backgroundColor: "#FFF",
        titleColor: "#2D3436",
        bodyColor: "#2D3436",
        borderColor: "#E6E6E6",
        borderWidth: 1,
        padding: 12,
        displayColors: false,
      },
    },
    scales: {
      x: {
        grid: { display: false },
        ticks: { font: { size: 10 }, maxRotation: 45, minRotation: 0 },
      },
      y: { grid: { borderDash: [5, 5] }, beginAtZero: true },
    },
  };

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom>
          Dashboard Overview
        </Typography>
        <Typography color="text.secondary">
          Real-time platform metrics and analytics.
        </Typography>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard
            title="Total Users"
            value={
              stats?.stats?.totalUsers ? stats.stats.totalUsers.toString() : "0"
            }
            icon={<Users size={24} />}
            color="primary"
            subtitle={`${stats?.stats?.recentOrders ?? 0} orders today`}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard
            title="Total Providers"
            value={
              stats?.stats?.totalProviders
                ? stats.stats.totalProviders.toString()
                : "0"
            }
            icon={<Store size={24} />}
            color="secondary"
            subtitle={`${stats?.stats?.activeProviders ?? 0} active`}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard
            title="Total Bookings"
            value={
              stats?.stats?.totalBookings
                ? stats.stats.totalBookings.toString()
                : "0"
            }
            icon={<CalendarCheck size={24} />}
            color="success"
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard
            title="Total Revenue"
            value={`Rs. ${(stats?.stats?.totalRevenue ? stats.stats.totalRevenue : 0).toLocaleString()}`}
            icon={<DollarSign size={24} />}
            color="info"
            subtitle={`Commission: Rs. ${(stats?.stats?.totalCommission ? stats.stats.totalCommission : 0).toLocaleString()}`}
          />
        </Grid>
      </Grid>

      {/* Quick Actions */}
      <Grid container spacing={2} sx={{ mb: 4 }}>
        {[
          {
            label: "Review Providers",
            sub: `${stats?.stats?.pendingApprovals ? stats.stats.pendingApprovals : 0} awaiting`,
            icon: <CheckCircle size={18} />,
            color: "#FF6B2B",
            path: "/providers",
          },
          {
            label: "View Bookings",
            sub: `${stats?.stats?.totalBookings ? stats.stats.totalBookings : 0} total`,
            icon: <CalendarCheck size={18} />,
            color: "#2196F3",
            path: "/bookings",
          },
          {
            label: "Manage Services",
            sub: "All service types",
            icon: <ShoppingBag size={18} />,
            color: "#4CAF50",
            path: "/services",
          },
          {
            label: "Send Notification",
            sub: "Broadcast to users",
            icon: <Bell size={18} />,
            color: "#9C27B0",
            path: "/notifications",
          },
        ].map((a, i) => (
          <Grid key={i} size={{ xs: 12, sm: 6, md: 3 }}>
            <Card
              onClick={() => navigate(a.path)}
              sx={{
                cursor: "pointer",
                display: "flex",
                alignItems: "center",
                gap: 2,
                p: 2,
                transition: "all 0.2s",
                "&:hover": { transform: "translateY(-2px)", boxShadow: 4 },
                border: `1.5px solid ${a.color}22`,
              }}
            >
              <Box
                sx={{
                  p: 1.5,
                  borderRadius: 2,
                  bgcolor: `${a.color}18`,
                  color: a.color,
                }}
              >
                {a.icon}
              </Box>
              <Box>
                <Typography variant="subtitle2" fontWeight={700}>
                  {a.label}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {a.sub}
                </Typography>
              </Box>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Charts */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid size={{ xs: 12, lg: 7 }}>
          <Card>
            <CardContent>
              <Box
                sx={{ display: "flex", justifyContent: "space-between", mb: 3 }}
              >
                <Typography variant="h6">User Growth (30 days)</Typography>
                <Chip
                  size="small"
                  icon={<ArrowUpRight size={14} />}
                  label="Live Data"
                  color="success"
                  variant="outlined"
                />
              </Box>
              <Box sx={{ height: 300 }}>
                <Line data={userGrowthData} options={chartOptions} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, lg: 5 }}>
          <Card>
            <CardContent>
              <Box
                sx={{ display: "flex", justifyContent: "space-between", mb: 3 }}
              >
                <Typography variant="h6">Booking Activity</Typography>
                <Chip
                  size="small"
                  icon={<TrendingUp size={14} />}
                  label="30 days"
                  variant="outlined"
                />
              </Box>
              <Box sx={{ height: 300 }}>
                <Bar data={bookingGrowthData} options={chartOptions} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Bottom Section */}
      <Grid container spacing={3}>
        <Grid size={{ xs: 12, lg: 8 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Recent Bookings
              </Typography>
              <TableContainer>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Order</TableCell>
                      <TableCell>Customer</TableCell>
                      <TableCell>Service</TableCell>
                      <TableCell>Amount</TableCell>
                      <TableCell>Status</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {(stats?.recentBookings || []).map((b) => (
                      <TableRow key={b._id} hover>
                        <TableCell>
                          <Typography variant="body2" fontWeight={600}>
                            {b.orderNumber}
                          </Typography>
                        </TableCell>
                        <TableCell>{b.name}</TableCell>
                        <TableCell>{b.providerServiceName || "N/A"}</TableCell>
                        <TableCell>Rs. {b.totalAmount}</TableCell>
                        <TableCell>
                          <Chip
                            size="small"
                            label={b.status}
                            color={statusColors[b.status] || "default"}
                          />
                        </TableCell>
                      </TableRow>
                    ))}
                    {(!stats?.recentBookings ||
                      stats.recentBookings.length === 0) && (
                      <TableRow>
                        <TableCell colSpan={5} align="center" sx={{ py: 4 }}>
                          <Typography color="text.secondary">
                            No recent bookings.
                          </Typography>
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, lg: 4 }}>
          <Card sx={{ height: "100%" }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Pending Actions
              </Typography>
              <Box
                sx={{ display: "flex", flexDirection: "column", gap: 2, mt: 2 }}
              >
                <Box
                  sx={{
                    p: 2,
                    borderRadius: 2,
                    bgcolor: "rgba(30, 41, 59, 0.06)",
                    border: "1px solid rgba(30, 41, 59, 0.15)",
                  }}
                >
                  <Box
                    sx={{
                      display: "flex",
                      alignItems: "center",
                      gap: 1,
                      mb: 0.5,
                    }}
                  >
                    <ShieldAlert size={16} color="#1E293B" />
                    <Typography variant="subtitle2" color="primary.main">
                      {stats?.stats?.pendingApprovals ?? 0} Providers
                    </Typography>
                  </Box>
                  <Typography variant="caption" color="text.secondary">
                    Waiting for approval
                  </Typography>
                </Box>
                <Box
                  sx={{
                    p: 2,
                    borderRadius: 2,
                    bgcolor: "rgba(142, 45, 226, 0.06)",
                    border: "1px solid rgba(142, 45, 226, 0.15)",
                  }}
                >
                  <Box
                    sx={{
                      display: "flex",
                      alignItems: "center",
                      gap: 1,
                      mb: 0.5,
                    }}
                  >
                    <Clock size={16} color="#8E2DE2" />
                    <Typography variant="subtitle2" color="secondary.main">
                      {stats?.stats?.suspendedProviders ?? 0} Suspended
                    </Typography>
                  </Box>
                  <Typography variant="caption" color="text.secondary">
                    Providers currently suspended
                  </Typography>
                </Box>
                <Box
                  sx={{
                    p: 2,
                    borderRadius: 2,
                    bgcolor: "rgba(76, 175, 80, 0.06)",
                    border: "1px solid rgba(76, 175, 80, 0.15)",
                  }}
                >
                  <Box
                    sx={{
                      display: "flex",
                      alignItems: "center",
                      gap: 1,
                      mb: 0.5,
                    }}
                  >
                    <DollarSign size={16} color="#4CAF50" />
                    <Typography variant="subtitle2" color="success.main">
                      Rs. {(stats?.stats?.pendingPayouts ?? 0).toLocaleString()}
                    </Typography>
                  </Box>
                  <Typography variant="caption" color="text.secondary">
                    Provider earnings to settle
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard;
