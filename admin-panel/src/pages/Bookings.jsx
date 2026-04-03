import { useState, useEffect, useCallback } from 'react';
import {
    Box,
    Typography,
    Card,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Chip,
    IconButton,
    Tooltip,
    CircularProgress,
    Snackbar,
    Alert,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    Button,
    Grid,
    Divider,
    Tabs,
    Tab,
} from '@mui/material';
import { Eye, XCircle, CalendarDays, User as UserIcon, Store } from 'lucide-react';
import api from '../utils/api';

const statusColors = {
    Pending: 'warning',
    Confirmed: 'info',
    Preparing: 'info',
    'Ready for Delivery': 'secondary',
    'Out for Delivery': 'secondary',
    Delivered: 'success',
    Completed: 'success',
    Cancelled: 'error',
    Rejected: 'error',
    Scheduled: 'info',
    'In Progress': 'primary',
    'On the Way': 'secondary',
    'On Hold': 'default',
};

const Bookings = () => {
    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);
    const [tab, setTab] = useState(0);
    const [selectedBooking, setSelectedBooking] = useState(null);
    const [detailOpen, setDetailOpen] = useState(false);
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });

    const tabStatuses = [null, 'Pending', 'Confirmed', 'Delivered', 'Cancelled'];
    const tabLabels = ['All', 'Pending', 'Confirmed', 'Delivered', 'Cancelled'];

    const fetchBookings = useCallback(async () => {
        try {
            setLoading(true);
            const status = tabStatuses[tab];
            const url = status ? `/admin/bookings?status=${status}` : '/admin/bookings';
            const response = await api.get(url);
            setBookings(response.data.bookings || []);
        } catch (error) {
            console.error('Failed to fetch bookings:', error);
            setBookings([]);
        } finally {
            setLoading(false);
        }
    }, [tab]);

    useEffect(() => {
        fetchBookings();
    }, [fetchBookings]);

    const handleCancelBooking = async (id) => {
        if (!window.confirm('Are you sure you want to cancel this booking?')) return;
        try {
            await api.patch(`/admin/bookings/${id}/cancel`, { reason: 'Cancelled by Admin' });
            setSnackbar({ open: true, message: 'Booking cancelled successfully', severity: 'success' });
            setDetailOpen(false);
            fetchBookings();
        } catch (error) {
            setSnackbar({ open: true, message: 'Failed to cancel booking', severity: 'error' });
        }
    };

    return (
        <Box>
            <Box sx={{ mb: 4 }}>
                <Typography variant="h4" gutterBottom>
                    Bookings & Orders
                </Typography>
                <Typography color="text.secondary">
                    Monitor and manage all platform bookings.
                </Typography>
            </Box>

            <Card>
                <Tabs
                    value={tab}
                    onChange={(e, v) => setTab(v)}
                    sx={{ borderBottom: 1, borderColor: 'divider', px: 2 }}
                >
                    {tabLabels.map((label, idx) => (
                        <Tab key={idx} label={label} />
                    ))}
                </Tabs>

                {loading ? (
                    <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
                        <CircularProgress />
                    </Box>
                ) : (
                    <TableContainer>
                        <Table>
                            <TableHead>
                                <TableRow>
                                    <TableCell>Order #</TableCell>
                                    <TableCell>Customer</TableCell>
                                    <TableCell>Provider</TableCell>
                                    <TableCell>Service</TableCell>
                                    <TableCell>Amount</TableCell>
                                    <TableCell>Payment</TableCell>
                                    <TableCell>Status</TableCell>
                                    <TableCell>Date</TableCell>
                                    <TableCell align="right">Actions</TableCell>
                                </TableRow>
                            </TableHead>
                            <TableBody>
                                {bookings.map((booking) => (
                                    <TableRow key={booking._id} hover>
                                        <TableCell>
                                            <Typography variant="body2" fontWeight={700}>{booking.orderNumber}</Typography>
                                        </TableCell>
                                        <TableCell>{booking.name || `${booking.firstName} ${booking.lastName}`}</TableCell>
                                        <TableCell>{booking.providerName || `${booking.providerFirstName || ''} ${booking.providerLastName || ''}`.trim() || 'N/A'}</TableCell>
                                        <TableCell>{booking.providerServiceName || (booking.items?.[0]?.serviceName) || 'N/A'}</TableCell>
                                        <TableCell>
                                            <Typography variant="body2" fontWeight={600}>Rs. {booking.totalAmount}</Typography>
                                        </TableCell>
                                        <TableCell>
                                            <Chip
                                                size="small"
                                                label={booking.paymentStatus || 'Pending'}
                                                color={booking.paymentStatus === 'Completed' ? 'success' : 'warning'}
                                            />
                                        </TableCell>
                                        <TableCell>
                                            <Chip
                                                size="small"
                                                label={booking.status}
                                                color={statusColors[booking.status] || 'default'}
                                            />
                                        </TableCell>
                                        <TableCell>
                                            <Typography variant="caption">{new Date(booking.createdAt).toLocaleDateString()}</Typography>
                                        </TableCell>
                                        <TableCell align="right">
                                            <Tooltip title="View Details">
                                                <IconButton size="small" onClick={() => { setSelectedBooking(booking); setDetailOpen(true); }}>
                                                    <Eye size={18} />
                                                </IconButton>
                                            </Tooltip>
                                            {booking.status !== 'Cancelled' && booking.status !== 'Delivered' && booking.status !== 'Completed' && (
                                                <Tooltip title="Cancel">
                                                    <IconButton size="small" color="error" onClick={() => handleCancelBooking(booking._id)}>
                                                        <XCircle size={18} />
                                                    </IconButton>
                                                </Tooltip>
                                            )}
                                        </TableCell>
                                    </TableRow>
                                ))}
                                {bookings.length === 0 && (
                                    <TableRow>
                                        <TableCell colSpan={9} align="center" sx={{ py: 10 }}>
                                            <Typography color="text.secondary">No bookings found.</Typography>
                                        </TableCell>
                                    </TableRow>
                                )}
                            </TableBody>
                        </Table>
                    </TableContainer>
                )}
            </Card>

            {/* Booking Detail Dialog */}
            <Dialog open={detailOpen} onClose={() => setDetailOpen(false)} maxWidth="md" fullWidth>
                {selectedBooking && (
                    <>
                        <DialogTitle>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                Order {selectedBooking.orderNumber}
                                <Chip label={selectedBooking.status} color={statusColors[selectedBooking.status] || 'default'} />
                            </Box>
                        </DialogTitle>
                        <DialogContent dividers>
                            <Grid container spacing={3}>
                                <Grid size={{ xs: 12, md: 6 }}>
                                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                                        <UserIcon size={18} />
                                        <Typography variant="subtitle2" fontWeight={700}>Customer Details</Typography>
                                    </Box>
                                    <Typography variant="body2">Name: {selectedBooking.name || `${selectedBooking.firstName} ${selectedBooking.lastName}`}</Typography>
                                    <Typography variant="body2">Email: {selectedBooking.email}</Typography>
                                    <Typography variant="body2">Phone: {selectedBooking.phone}</Typography>
                                    <Typography variant="body2">Address: {selectedBooking.deliveryAddress || selectedBooking.address}</Typography>
                                </Grid>
                                <Grid size={{ xs: 12, md: 6 }}>
                                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                                        <Store size={18} />
                                        <Typography variant="subtitle2" fontWeight={700}>Provider Details</Typography>
                                    </Box>
                                    <Typography variant="body2">Name: {selectedBooking.providerName || 'N/A'}</Typography>
                                    <Typography variant="body2">Email: {selectedBooking.providerEmail || 'N/A'}</Typography>
                                    <Typography variant="body2">Phone: {selectedBooking.providerPhone || 'N/A'}</Typography>
                                    <Typography variant="body2">Service: {selectedBooking.providerServiceName || 'N/A'}</Typography>
                                </Grid>
                            </Grid>
                            <Divider sx={{ my: 2 }} />
                            <Typography variant="subtitle2" fontWeight={700} gutterBottom>Order Items</Typography>
                            {selectedBooking.items?.map((item, idx) => (
                                <Box key={idx} sx={{ display: 'flex', justifyContent: 'space-between', p: 1.5, bgcolor: '#f8f9fa', borderRadius: 1, mb: 1 }}>
                                    <Box>
                                        <Typography variant="body2" fontWeight={600}>{item.serviceName}</Typography>
                                        <Typography variant="caption" color="text.secondary">Qty: {item.quantity}</Typography>
                                    </Box>
                                    <Typography variant="body2" fontWeight={600}>Rs. {item.totalPrice}</Typography>
                                </Box>
                            )) || <Typography variant="body2" color="text.secondary">No items</Typography>}
                            <Divider sx={{ my: 2 }} />
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                <Box>
                                    <Typography variant="body2">Payment: {selectedBooking.paymentMethod}</Typography>
                                    <Typography variant="body2">Payment Status: {selectedBooking.paymentStatus}</Typography>
                                </Box>
                                <Box sx={{ textAlign: 'right' }}>
                                    <Typography variant="body2">Subtotal: Rs. {selectedBooking.subtotal}</Typography>
                                    <Typography variant="body2">Delivery: Rs. {selectedBooking.deliveryFee || 0}</Typography>
                                    <Typography variant="h6" fontWeight={700} color="primary.main">Total: Rs. {selectedBooking.totalAmount}</Typography>
                                </Box>
                            </Box>
                            {selectedBooking.specialInstructions && (
                                <>
                                    <Divider sx={{ my: 2 }} />
                                    <Typography variant="subtitle2" gutterBottom>Special Instructions</Typography>
                                    <Typography variant="body2" color="text.secondary">{selectedBooking.specialInstructions}</Typography>
                                </>
                            )}
                            {selectedBooking.cancellationReason && (
                                <>
                                    <Divider sx={{ my: 2 }} />
                                    <Alert severity="error">Cancellation Reason: {selectedBooking.cancellationReason}</Alert>
                                </>
                            )}
                            <Typography variant="caption" color="text.secondary" display="block" sx={{ mt: 2 }}>
                                <CalendarDays size={12} style={{ verticalAlign: 'middle', marginRight: 4 }} />
                                Order placed: {new Date(selectedBooking.createdAt).toLocaleString()}
                            </Typography>
                        </DialogContent>
                        <DialogActions>
                            <Button onClick={() => setDetailOpen(false)}>Close</Button>
                            {selectedBooking.status !== 'Cancelled' && selectedBooking.status !== 'Delivered' && selectedBooking.status !== 'Completed' && (
                                <Button
                                    variant="contained"
                                    color="error"
                                    startIcon={<XCircle size={16} />}
                                    onClick={() => handleCancelBooking(selectedBooking._id)}
                                >
                                    Cancel Order
                                </Button>
                            )}
                        </DialogActions>
                    </>
                )}
            </Dialog>

            <Snackbar
                open={snackbar.open}
                autoHideDuration={4000}
                onClose={() => setSnackbar(s => ({ ...s, open: false }))}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
            >
                <Alert severity={snackbar.severity} onClose={() => setSnackbar(s => ({ ...s, open: false }))}>
                    {snackbar.message}
                </Alert>
            </Snackbar>
        </Box>
    );
};

export default Bookings;
