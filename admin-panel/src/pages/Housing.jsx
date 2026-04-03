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
    Avatar,
    Chip,
    IconButton,
    Button,
    Tabs,
    Tab,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    Grid,
    Divider,
    Tooltip,
    Alert,
    CircularProgress,
    Snackbar,
    TextField,
    Stack,
} from '@mui/material';
import {
    Eye,
    CheckCircle,
    XCircle,
    ShieldAlert,
    Trash2,
    Home,
    MapPin,
    DollarSign,
    Users,
    Bed,
    Bath,
} from 'lucide-react';
import api from '../utils/api';

const statusColors = {
    pending_approval: 'warning',
    approved: 'success',
    rejected: 'error',
    suspended: 'default',
};

const Housing = () => {
    const [properties, setProperties] = useState([]);
    const [loading, setLoading] = useState(true);
    const [tabValue, setTabValue] = useState(0);
    const [selectedProperty, setSelectedProperty] = useState(null);
    const [detailOpen, setDetailOpen] = useState(false);
    const [actionLoading, setActionLoading] = useState(false);
    const [rejectionReason, setRejectionReason] = useState('');
    const [stats, setStats] = useState(null);
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });

    const statusMap = ['pending_approval', 'approved', 'rejected', 'suspended'];

    const fetchProperties = useCallback(async () => {
        try {
            setLoading(true);
            const status = statusMap[tabValue];
            const response = await api.get(`/admin/housing?status=${status}`);
            setProperties(response.data.properties || []);
        } catch (error) {
            console.error('Failed to fetch properties:', error);
            setProperties([]);
        } finally {
            setLoading(false);
        }
    }, [tabValue]);

    const fetchStats = useCallback(async () => {
        try {
            const response = await api.get('/admin/housing/stats');
            setStats(response.data.stats);
        } catch (e) {
            console.error('Failed to fetch housing stats:', e);
        }
    }, []);

    useEffect(() => {
        fetchProperties();
        fetchStats();
    }, [fetchProperties, fetchStats]);

    const handleStatusUpdate = async (id, status) => {
        try {
            setActionLoading(true);
            const body = { status };
            if (status === 'rejected' && rejectionReason) {
                body.rejectionReason = rejectionReason;
            }
            await api.patch(`/admin/housing/${id}/status`, body);
            setSnackbar({ open: true, message: `Property ${status} successfully`, severity: 'success' });
            setDetailOpen(false);
            setSelectedProperty(null);
            setRejectionReason('');
            fetchProperties();
            fetchStats();
        } catch (error) {
            setSnackbar({ open: true, message: error.response?.data?.message || 'Action failed', severity: 'error' });
        } finally {
            setActionLoading(false);
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm('Are you sure you want to permanently delete this property?')) return;
        try {
            setActionLoading(true);
            await api.delete(`/admin/housing/${id}`);
            setSnackbar({ open: true, message: 'Property deleted', severity: 'success' });
            setDetailOpen(false);
            fetchProperties();
            fetchStats();
        } catch (error) {
            setSnackbar({ open: true, message: 'Delete failed', severity: 'error' });
        } finally {
            setActionLoading(false);
        }
    };

    const viewProperty = async (id) => {
        try {
            const response = await api.get(`/admin/housing/${id}`);
            setSelectedProperty(response.data.property);
            setDetailOpen(true);
        } catch {
            setSnackbar({ open: true, message: 'Failed to load property details', severity: 'error' });
        }
    };

    return (
        <Box sx={{ p: 3 }}>
            <Typography variant="h4" fontWeight="bold" gutterBottom>
                <Home style={{ verticalAlign: 'middle', marginRight: 8 }} />
                Housing Management
            </Typography>

            {/* Stats Cards */}
            {stats && (
                <Grid container spacing={2} sx={{ mb: 3 }}>
                    {[
                        { label: 'Total Properties', value: stats.total, color: '#FF9D42' },
                        { label: 'Pending Approval', value: stats.pending, color: '#FFA726' },
                        { label: 'Approved', value: stats.approved, color: '#66BB6A' },
                        { label: 'Rejected', value: stats.rejected, color: '#EF5350' },
                        { label: 'Total Bookings', value: stats.totalBookings, color: '#42A5F5' },
                        { label: 'Platform Earnings', value: `Rs ${(stats.platformEarnings || 0).toLocaleString()}`, color: '#AB47BC' },
                    ].map((s, i) => (
                        <Grid item xs={6} md={2} key={i}>
                            <Card sx={{ p: 2, textAlign: 'center', borderTop: `3px solid ${s.color}` }}>
                                <Typography variant="h5" fontWeight="bold" color={s.color}>
                                    {s.value}
                                </Typography>
                                <Typography variant="caption" color="text.secondary">
                                    {s.label}
                                </Typography>
                            </Card>
                        </Grid>
                    ))}
                </Grid>
            )}

            {/* Tabs */}
            <Card sx={{ mb: 3 }}>
                <Tabs
                    value={tabValue}
                    onChange={(_, v) => setTabValue(v)}
                    variant="fullWidth"
                    indicatorColor="primary"
                    sx={{ borderBottom: 1, borderColor: 'divider' }}
                >
                    <Tab label={`Pending (${stats?.pending || 0})`} />
                    <Tab label={`Approved (${stats?.approved || 0})`} />
                    <Tab label={`Rejected (${stats?.rejected || 0})`} />
                    <Tab label={`Suspended (${stats?.suspended || 0})`} />
                </Tabs>

                {loading ? (
                    <Box display="flex" justifyContent="center" p={4}>
                        <CircularProgress />
                    </Box>
                ) : properties.length === 0 ? (
                    <Box p={4} textAlign="center">
                        <Typography color="text.secondary">No properties found</Typography>
                    </Box>
                ) : (
                    <TableContainer>
                        <Table>
                            <TableHead>
                                <TableRow>
                                    <TableCell>Property</TableCell>
                                    <TableCell>Owner</TableCell>
                                    <TableCell>Type</TableCell>
                                    <TableCell>City</TableCell>
                                    <TableCell>Rent</TableCell>
                                    <TableCell>Status</TableCell>
                                    <TableCell align="right">Actions</TableCell>
                                </TableRow>
                            </TableHead>
                            <TableBody>
                                {properties.map((p) => {
                                    const owner = p.ownerId || {};
                                    const images = p.images || [];
                                    return (
                                        <TableRow key={p._id} hover>
                                            <TableCell>
                                                <Box display="flex" alignItems="center" gap={1.5}>
                                                    <Avatar
                                                        variant="rounded"
                                                        src={images[0] || ''}
                                                        sx={{ width: 48, height: 48, bgcolor: '#FF9D42' }}
                                                    >
                                                        <Home size={20} />
                                                    </Avatar>
                                                    <Box>
                                                        <Typography fontWeight={600} fontSize={14} noWrap sx={{ maxWidth: 200 }}>
                                                            {p.title}
                                                        </Typography>
                                                        <Typography variant="caption" color="text.secondary">
                                                            {p.bedrooms || 1} bed · {p.bathrooms || 1} bath
                                                        </Typography>
                                                    </Box>
                                                </Box>
                                            </TableCell>
                                            <TableCell>
                                                <Typography fontSize={13}>
                                                    {owner.firstName} {owner.lastName}
                                                </Typography>
                                                <Typography variant="caption" color="text.secondary">
                                                    {owner.email}
                                                </Typography>
                                            </TableCell>
                                            <TableCell>
                                                <Chip label={p.propertyType} size="small" />
                                            </TableCell>
                                            <TableCell>{p.city}</TableCell>
                                            <TableCell>
                                                <Typography fontWeight={600} color="#FF9D42">
                                                    Rs {(p.monthlyRent || 0).toLocaleString()}
                                                </Typography>
                                            </TableCell>
                                            <TableCell>
                                                <Chip
                                                    label={p.status?.replace('_', ' ')}
                                                    color={statusColors[p.status] || 'default'}
                                                    size="small"
                                                    sx={{ textTransform: 'capitalize' }}
                                                />
                                            </TableCell>
                                            <TableCell align="right">
                                                <Tooltip title="View Details">
                                                    <IconButton onClick={() => viewProperty(p._id)} size="small">
                                                        <Eye size={18} />
                                                    </IconButton>
                                                </Tooltip>
                                                {p.status === 'pending_approval' && (
                                                    <>
                                                        <Tooltip title="Approve">
                                                            <IconButton
                                                                onClick={() => handleStatusUpdate(p._id, 'approved')}
                                                                size="small"
                                                                color="success"
                                                            >
                                                                <CheckCircle size={18} />
                                                            </IconButton>
                                                        </Tooltip>
                                                        <Tooltip title="Reject">
                                                            <IconButton
                                                                onClick={() => {
                                                                    setSelectedProperty(p);
                                                                    setDetailOpen(true);
                                                                }}
                                                                size="small"
                                                                color="error"
                                                            >
                                                                <XCircle size={18} />
                                                            </IconButton>
                                                        </Tooltip>
                                                    </>
                                                )}
                                                <Tooltip title="Delete">
                                                    <IconButton
                                                        onClick={() => handleDelete(p._id)}
                                                        size="small"
                                                        color="error"
                                                    >
                                                        <Trash2 size={18} />
                                                    </IconButton>
                                                </Tooltip>
                                            </TableCell>
                                        </TableRow>
                                    );
                                })}
                            </TableBody>
                        </Table>
                    </TableContainer>
                )}
            </Card>

            {/* Property Detail Dialog */}
            <Dialog open={detailOpen} onClose={() => setDetailOpen(false)} maxWidth="md" fullWidth>
                {selectedProperty && (
                    <>
                        <DialogTitle sx={{ fontWeight: 700 }}>
                            {selectedProperty.title}
                        </DialogTitle>
                        <DialogContent dividers>
                            <Grid container spacing={3}>
                                {/* Images */}
                                <Grid item xs={12}>
                                    <Stack direction="row" spacing={1} sx={{ overflowX: 'auto', pb: 1 }}>
                                        {(selectedProperty.images || []).map((img, i) => (
                                            <img
                                                key={i}
                                                src={img}
                                                alt={`Property ${i + 1}`}
                                                style={{
                                                    width: 160,
                                                    height: 120,
                                                    objectFit: 'cover',
                                                    borderRadius: 12,
                                                    flexShrink: 0,
                                                }}
                                            />
                                        ))}
                                        {(!selectedProperty.images || selectedProperty.images.length === 0) && (
                                            <Box
                                                sx={{
                                                    width: 160,
                                                    height: 120,
                                                    bgcolor: '#f5f5f5',
                                                    borderRadius: 3,
                                                    display: 'flex',
                                                    alignItems: 'center',
                                                    justifyContent: 'center',
                                                }}
                                            >
                                                <Home size={40} color="#ccc" />
                                            </Box>
                                        )}
                                    </Stack>
                                </Grid>

                                {/* Info Grid */}
                                <Grid item xs={6}>
                                    <Typography variant="caption" color="text.secondary">
                                        Type
                                    </Typography>
                                    <Typography fontWeight={600}>{selectedProperty.propertyType}</Typography>
                                </Grid>
                                <Grid item xs={6}>
                                    <Typography variant="caption" color="text.secondary">
                                        City
                                    </Typography>
                                    <Typography fontWeight={600}>
                                        <MapPin size={14} style={{ verticalAlign: 'middle' }} />{' '}
                                        {selectedProperty.city}
                                    </Typography>
                                </Grid>
                                <Grid item xs={6}>
                                    <Typography variant="caption" color="text.secondary">
                                        Monthly Rent
                                    </Typography>
                                    <Typography fontWeight={700} color="#FF9D42" fontSize={18}>
                                        Rs {(selectedProperty.monthlyRent || 0).toLocaleString()}
                                    </Typography>
                                </Grid>
                                <Grid item xs={6}>
                                    <Typography variant="caption" color="text.secondary">
                                        Security Deposit
                                    </Typography>
                                    <Typography fontWeight={600}>
                                        Rs {(selectedProperty.securityDeposit || 0).toLocaleString()}
                                    </Typography>
                                </Grid>
                                <Grid item xs={4}>
                                    <Typography variant="caption" color="text.secondary">
                                        Bedrooms
                                    </Typography>
                                    <Typography fontWeight={600}>
                                        <Bed size={14} style={{ verticalAlign: 'middle' }} />{' '}
                                        {selectedProperty.bedrooms || 1}
                                    </Typography>
                                </Grid>
                                <Grid item xs={4}>
                                    <Typography variant="caption" color="text.secondary">
                                        Bathrooms
                                    </Typography>
                                    <Typography fontWeight={600}>
                                        <Bath size={14} style={{ verticalAlign: 'middle' }} />{' '}
                                        {selectedProperty.bathrooms || 1}
                                    </Typography>
                                </Grid>
                                <Grid item xs={4}>
                                    <Typography variant="caption" color="text.secondary">
                                        Furnished
                                    </Typography>
                                    <Typography fontWeight={600}>
                                        {selectedProperty.furnished || 'Unfurnished'}
                                    </Typography>
                                </Grid>
                                <Grid item xs={12}>
                                    <Divider sx={{ my: 1 }} />
                                    <Typography variant="caption" color="text.secondary">
                                        Description
                                    </Typography>
                                    <Typography fontSize={14}>
                                        {selectedProperty.description || 'No description'}
                                    </Typography>
                                </Grid>
                                <Grid item xs={12}>
                                    <Typography variant="caption" color="text.secondary">
                                        Address
                                    </Typography>
                                    <Typography fontSize={14}>{selectedProperty.address}</Typography>
                                </Grid>

                                {/* Owner Info */}
                                <Grid item xs={12}>
                                    <Divider sx={{ my: 1 }} />
                                    <Typography fontWeight={600} gutterBottom>
                                        Owner Information
                                    </Typography>
                                    {selectedProperty.ownerId && (
                                        <Box display="flex" alignItems="center" gap={2}>
                                            <Avatar
                                                src={selectedProperty.ownerId.profileImage}
                                                sx={{ width: 40, height: 40 }}
                                            >
                                                {(selectedProperty.ownerId.firstName || 'O')[0]}
                                            </Avatar>
                                            <Box>
                                                <Typography fontWeight={600}>
                                                    {selectedProperty.ownerId.firstName}{' '}
                                                    {selectedProperty.ownerId.lastName}
                                                </Typography>
                                                <Typography variant="caption" color="text.secondary">
                                                    {selectedProperty.ownerId.email} ·{' '}
                                                    {selectedProperty.ownerId.phone}
                                                </Typography>
                                            </Box>
                                        </Box>
                                    )}
                                </Grid>

                                {/* Rejection reason input (for pending properties) */}
                                {selectedProperty.status === 'pending_approval' && (
                                    <Grid item xs={12}>
                                        <Divider sx={{ my: 1 }} />
                                        <TextField
                                            label="Rejection Reason (if rejecting)"
                                            value={rejectionReason}
                                            onChange={(e) => setRejectionReason(e.target.value)}
                                            fullWidth
                                            multiline
                                            rows={2}
                                            placeholder="Enter reason for rejection..."
                                        />
                                    </Grid>
                                )}
                            </Grid>
                        </DialogContent>
                        <DialogActions sx={{ p: 2, gap: 1 }}>
                            {selectedProperty.status === 'pending_approval' && (
                                <>
                                    <Button
                                        variant="contained"
                                        color="success"
                                        startIcon={<CheckCircle size={16} />}
                                        onClick={() => handleStatusUpdate(selectedProperty._id, 'approved')}
                                        disabled={actionLoading}
                                    >
                                        Approve
                                    </Button>
                                    <Button
                                        variant="contained"
                                        color="error"
                                        startIcon={<XCircle size={16} />}
                                        onClick={() => handleStatusUpdate(selectedProperty._id, 'rejected')}
                                        disabled={actionLoading}
                                    >
                                        Reject
                                    </Button>
                                </>
                            )}
                            {selectedProperty.status === 'approved' && (
                                <Button
                                    variant="contained"
                                    color="warning"
                                    startIcon={<ShieldAlert size={16} />}
                                    onClick={() => handleStatusUpdate(selectedProperty._id, 'suspended')}
                                    disabled={actionLoading}
                                >
                                    Suspend
                                </Button>
                            )}
                            {(selectedProperty.status === 'rejected' || selectedProperty.status === 'suspended') && (
                                <Button
                                    variant="contained"
                                    color="success"
                                    startIcon={<CheckCircle size={16} />}
                                    onClick={() => handleStatusUpdate(selectedProperty._id, 'approved')}
                                    disabled={actionLoading}
                                >
                                    Re-Approve
                                </Button>
                            )}
                            <Button
                                variant="outlined"
                                color="error"
                                startIcon={<Trash2 size={16} />}
                                onClick={() => handleDelete(selectedProperty._id)}
                                disabled={actionLoading}
                            >
                                Delete
                            </Button>
                            <Button onClick={() => setDetailOpen(false)}>Close</Button>
                        </DialogActions>
                    </>
                )}
            </Dialog>

            {/* Snackbar */}
            <Snackbar
                open={snackbar.open}
                autoHideDuration={4000}
                onClose={() => setSnackbar({ ...snackbar, open: false })}
            >
                <Alert severity={snackbar.severity} onClose={() => setSnackbar({ ...snackbar, open: false })}>
                    {snackbar.message}
                </Alert>
            </Snackbar>
        </Box>
    );
};

export default Housing;
