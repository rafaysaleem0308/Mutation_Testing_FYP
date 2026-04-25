import { useState } from 'react';
import {
    Box,
    Typography,
    Card,
    CardContent,
    TextField,
    Button,
    Alert,
    Snackbar,
    ToggleButton,
    ToggleButtonGroup,
    CircularProgress,
} from '@mui/material';
import { Send, Bell, Users, Store } from 'lucide-react';
import api from '../utils/api';

const Notifications = () => {
    const [target, setTarget] = useState('all');
    const [title, setTitle] = useState('');
    const [message, setMessage] = useState('');
    const [loading, setLoading] = useState(false);
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });

    const handleSend = async () => {
        if (!title.trim() || !message.trim()) {
            setSnackbar({ open: true, message: 'Title and message are required', severity: 'error' });
            return;
        }

        try {
            setLoading(true);
            const response = await api.post('/admin/notifications/send', {
                target,
                title: title.trim(),
                message: message.trim(),
            });
            setSnackbar({
                open: true,
                message: response.data.message || 'Notification sent successfully',
                severity: 'success',
            });
            setTitle('');
            setMessage('');
        } catch (error) {
            setSnackbar({
                open: true,
                message: error.response?.data?.message || 'Failed to send notification',
                severity: 'error',
            });
        } finally {
            setLoading(false);
        }
    };

    return (
        <Box>
            <Box sx={{ mb: 4 }}>
                <Typography variant="h4" gutterBottom>
                    Push Notifications
                </Typography>
                <Typography color="text.secondary">
                    Send broadcast notifications to users and providers on the mobile app.
                </Typography>
            </Box>

            <Card sx={{ maxWidth: 700 }}>
                <CardContent sx={{ p: 4 }}>
                    <Box sx={{ mb: 4 }}>
                        <Typography variant="subtitle1" fontWeight={700} gutterBottom>
                            Select Audience
                        </Typography>
                        <ToggleButtonGroup
                            value={target}
                            exclusive
                            onChange={(e, v) => { if (v) setTarget(v); }}
                            sx={{ mt: 1 }}
                        >
                            <ToggleButton value="all" sx={{ px: 3 }}>
                                <Bell size={16} style={{ marginRight: 8 }} /> All
                            </ToggleButton>
                            <ToggleButton value="users" sx={{ px: 3 }}>
                                <Users size={16} style={{ marginRight: 8 }} /> Users Only
                            </ToggleButton>
                            <ToggleButton value="providers" sx={{ px: 3 }}>
                                <Store size={16} style={{ marginRight: 8 }} /> Providers Only
                            </ToggleButton>
                        </ToggleButtonGroup>
                    </Box>

                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                        <TextField
                            label="Notification Title"
                            variant="outlined"
                            fullWidth
                            value={title}
                            onChange={(e) => setTitle(e.target.value)}
                            placeholder="e.g. New Feature Update"
                        />
                        <TextField
                            label="Message Body"
                            variant="outlined"
                            fullWidth
                            multiline
                            rows={4}
                            value={message}
                            onChange={(e) => setMessage(e.target.value)}
                            placeholder="Write the notification message..."
                        />
                        <Button
                            variant="contained"
                            size="large"
                            startIcon={loading ? <CircularProgress size={20} color="inherit" /> : <Send size={18} />}
                            onClick={handleSend}
                            disabled={loading || !title.trim() || !message.trim()}
                            sx={{ alignSelf: 'flex-start', px: 4 }}
                        >
                            {loading ? 'Sending...' : 'Send Notification'}
                        </Button>
                    </Box>

                    <Alert severity="info" sx={{ mt: 4 }}>
                        Notifications are delivered in real-time via Socket.IO to connected mobile app users.
                    </Alert>
                </CardContent>
            </Card>

            <Snackbar
                open={snackbar.open}
                autoHideDuration={5000}
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

export default Notifications;
