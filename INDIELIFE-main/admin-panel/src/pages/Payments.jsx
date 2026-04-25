import { useState, useEffect, useCallback } from 'react';
import {
    Box,
    Typography,
    Card,
    CardContent,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Chip,
    CircularProgress,
    Grid,
} from '@mui/material';
import { DollarSign, TrendingUp, CreditCard, Clock } from 'lucide-react';
import api from '../utils/api';

const FinanceCard = ({ title, value, icon, color }) => (
    <Card>
        <CardContent sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Box>
                <Typography color="text.secondary" variant="body2" fontWeight={600} gutterBottom>
                    {title}
                </Typography>
                <Typography variant="h5" fontWeight={700}>
                    {value}
                </Typography>
            </Box>
            <Box sx={{ p: 1.5, borderRadius: 2, bgcolor: `${color}.light`, color: `${color}.main`, opacity: 0.85 }}>
                {icon}
            </Box>
        </CardContent>
    </Card>
);

const Payments = () => {
    const [payments, setPayments] = useState([]);
    const [stats, setStats] = useState(null);
    const [loading, setLoading] = useState(true);

    const fetchData = useCallback(async () => {
        try {
            setLoading(true);
            const [paymentsRes, statsRes] = await Promise.all([
                api.get('/admin/payments'),
                api.get('/admin/dashboard-stats'),
            ]);
            setPayments(paymentsRes.data.payments || []);
            setStats(statsRes.data.stats || null);
        } catch (error) {
            console.error('Failed to fetch payments:', error);
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchData();
    }, [fetchData]);

    if (loading) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '60vh' }}>
                <CircularProgress />
            </Box>
        );
    }

    return (
        <Box>
            <Box sx={{ mb: 4 }}>
                <Typography variant="h4" gutterBottom>
                    Payments & Commissions
                </Typography>
                <Typography color="text.secondary">
                    Track revenue, commissions, and provider earnings.
                </Typography>
            </Box>

            {/* Finance Cards */}
            <Grid container spacing={3} sx={{ mb: 4 }}>
                <Grid size={{ xs: 12, sm: 6, md: 3 }}>
                    <FinanceCard
                        title="Total Revenue"
                        value={`Rs. ${(stats?.totalRevenue ?? 0).toLocaleString()}`}
                        icon={<DollarSign size={24} />}
                        color="success"
                    />
                </Grid>
                <Grid size={{ xs: 12, sm: 6, md: 3 }}>
                    <FinanceCard
                        title="Platform Commission"
                        value={`Rs. ${(stats?.totalCommission ?? 0).toLocaleString()}`}
                        icon={<TrendingUp size={24} />}
                        color="primary"
                    />
                </Grid>
                <Grid size={{ xs: 12, sm: 6, md: 3 }}>
                    <FinanceCard
                        title="Provider Earnings"
                        value={`Rs. ${(stats?.pendingPayouts ?? 0).toLocaleString()}`}
                        icon={<CreditCard size={24} />}
                        color="secondary"
                    />
                </Grid>
                <Grid size={{ xs: 12, sm: 6, md: 3 }}>
                    <FinanceCard
                        title="Total Transactions"
                        value={payments.length}
                        icon={<Clock size={24} />}
                        color="info"
                    />
                </Grid>
            </Grid>

            {/* Transactions Table */}
            <Card>
                <CardContent>
                    <Typography variant="h6" gutterBottom>Transaction History</Typography>
                </CardContent>
                <TableContainer>
                    <Table>
                        <TableHead>
                            <TableRow>
                                <TableCell>Order #</TableCell>
                                <TableCell>Customer</TableCell>
                                <TableCell>Provider</TableCell>
                                <TableCell>Amount</TableCell>
                                <TableCell>Commission</TableCell>
                                <TableCell>Provider Earnings</TableCell>
                                <TableCell>Method</TableCell>
                                <TableCell>Status</TableCell>
                                <TableCell>Date</TableCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {payments.map((p) => (
                                <TableRow key={p._id} hover>
                                    <TableCell>
                                        <Typography variant="body2" fontWeight={700}>{p.orderNumber}</Typography>
                                    </TableCell>
                                    <TableCell>{p.name || 'N/A'}</TableCell>
                                    <TableCell>{p.providerName || 'N/A'}</TableCell>
                                    <TableCell>
                                        <Typography fontWeight={600} variant="body2">Rs. {p.totalAmount}</Typography>
                                    </TableCell>
                                    <TableCell>
                                        <Typography color="primary.main" fontWeight={600} variant="body2">Rs. {p.platformCommission || 0}</Typography>
                                    </TableCell>
                                    <TableCell>
                                        <Typography color="success.main" fontWeight={600} variant="body2">Rs. {p.providerEarnings || 0}</Typography>
                                    </TableCell>
                                    <TableCell>
                                        <Chip size="small" label={p.paymentMethod || 'N/A'} sx={{ borderRadius: 1.5 }} />
                                    </TableCell>
                                    <TableCell>
                                        <Chip
                                            size="small"
                                            label={p.paymentStatus}
                                            color={p.paymentStatus === 'Completed' ? 'success' : 'warning'}
                                        />
                                    </TableCell>
                                    <TableCell>
                                        <Typography variant="caption">{new Date(p.createdAt).toLocaleDateString()}</Typography>
                                    </TableCell>
                                </TableRow>
                            ))}
                            {payments.length === 0 && (
                                <TableRow>
                                    <TableCell colSpan={9} align="center" sx={{ py: 10 }}>
                                        <Typography color="text.secondary">No payment records found.</Typography>
                                    </TableCell>
                                </TableRow>
                            )}
                        </TableBody>
                    </Table>
                </TableContainer>
            </Card>
        </Box>
    );
};

export default Payments;
