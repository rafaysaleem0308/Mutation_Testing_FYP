import { useState, useEffect, useCallback } from 'react';
import {
    Box,
    Typography,
    Card,
    List,
    ListItemButton,
    ListItemText,
    ListItemAvatar,
    Avatar,
    Divider,
    CircularProgress,
    Chip,
    Paper,
} from '@mui/material';
import { MessageSquare } from 'lucide-react';
import api from '../utils/api';

const Chats = () => {
    const [chats, setChats] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selectedChat, setSelectedChat] = useState(null);
    const [messages, setMessages] = useState([]);
    const [msgsLoading, setMsgsLoading] = useState(false);

    const fetchChats = useCallback(async () => {
        try {
            setLoading(true);
            const response = await api.get('/admin/chats');
            setChats(response.data.chats || []);
        } catch (error) {
            console.error('Failed to fetch chats:', error);
            setChats([]);
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchChats();
    }, [fetchChats]);

    const openChat = async (chat) => {
        setSelectedChat(chat);
        setMsgsLoading(true);
        try {
            const response = await api.get(`/admin/chats/${chat._id}/messages`);
            setMessages(response.data.messages || []);
        } catch (error) {
            console.error('Failed to fetch messages:', error);
            setMessages([]);
        } finally {
            setMsgsLoading(false);
        }
    };

    const getParticipantName = (p) => {
        if (p.details) {
            return `${p.details.firstName || ''} ${p.details.lastName || ''}`.trim() || 'Unknown';
        }
        return 'Unknown';
    };

    const getChatTitle = (chat) => {
        if (!chat.participants || chat.participants.length === 0) return 'Unknown Chat';
        return chat.participants.map(p => getParticipantName(p)).join(' ↔ ');
    };

    const getChatSubtitle = (chat) => {
        if (chat.lastMessage?.content) return chat.lastMessage.content;
        return 'No messages yet';
    };

    return (
        <Box>
            <Box sx={{ mb: 4 }}>
                <Typography variant="h4" gutterBottom>
                    Chat Monitoring
                </Typography>
                <Typography color="text.secondary">
                    View and audit conversations between users and providers.
                </Typography>
            </Box>

            <Box sx={{ display: 'flex', gap: 3, height: 'calc(100vh - 220px)' }}>
                {/* Chat List */}
                <Card sx={{ width: 380, flexShrink: 0, display: 'flex', flexDirection: 'column' }}>
                    <Box sx={{ p: 2, borderBottom: 1, borderColor: 'divider' }}>
                        <Typography variant="subtitle1" fontWeight={700}>
                            Conversations ({chats.length})
                        </Typography>
                    </Box>
                    {loading ? (
                        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
                            <CircularProgress size={32} />
                        </Box>
                    ) : (
                        <List sx={{ overflow: 'auto', flex: 1 }}>
                            {chats.map((chat) => (
                                <Box key={chat._id}>
                                    <ListItemButton
                                        onClick={() => openChat(chat)}
                                        selected={selectedChat?._id === chat._id}
                                        sx={{
                                            '&.Mui-selected': {
                                                bgcolor: 'rgba(255, 157, 66, 0.08)',
                                                borderLeft: '3px solid #FF9D42',
                                            },
                                        }}
                                    >
                                        <ListItemAvatar>
                                            <Avatar sx={{ bgcolor: 'primary.light', color: 'primary.main' }}>
                                                <MessageSquare size={18} />
                                            </Avatar>
                                        </ListItemAvatar>
                                        <ListItemText
                                            primary={getChatTitle(chat)}
                                            secondary={getChatSubtitle(chat)}
                                            primaryTypographyProps={{ variant: 'subtitle2', noWrap: true }}
                                            secondaryTypographyProps={{ noWrap: true, variant: 'caption' }}
                                        />
                                    </ListItemButton>
                                    <Divider />
                                </Box>
                            ))}
                            {chats.length === 0 && (
                                <Box sx={{ p: 4, textAlign: 'center' }}>
                                    <Typography color="text.secondary" variant="body2">No conversations found.</Typography>
                                </Box>
                            )}
                        </List>
                    )}
                </Card>

                {/* Message Panel */}
                <Card sx={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
                    {!selectedChat ? (
                        <Box sx={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 2 }}>
                            <MessageSquare size={48} color="#ccc" />
                            <Typography color="text.secondary">Select a conversation to view messages</Typography>
                        </Box>
                    ) : (
                        <>
                            <Box sx={{ p: 2, borderBottom: 1, borderColor: 'divider', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                                <Box>
                                    <Typography variant="subtitle1" fontWeight={700}>{getChatTitle(selectedChat)}</Typography>
                                    <Typography variant="caption" color="text.secondary">
                                        {selectedChat.participants?.map(p => p.modelType).join(' & ')}
                                    </Typography>
                                </Box>
                                <Chip
                                    size="small"
                                    label={`${messages.length} messages`}
                                    variant="outlined"
                                />
                            </Box>
                            <Box sx={{ flex: 1, overflow: 'auto', p: 2, bgcolor: '#f8f9fa' }}>
                                {msgsLoading ? (
                                    <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
                                        <CircularProgress size={28} />
                                    </Box>
                                ) : messages.length === 0 ? (
                                    <Box sx={{ textAlign: 'center', py: 4 }}>
                                        <Typography color="text.secondary">No messages in this conversation.</Typography>
                                    </Box>
                                ) : (
                                    messages.map((msg, idx) => (
                                        <Box key={msg._id || idx} sx={{ mb: 2, display: 'flex', flexDirection: 'column' }}>
                                            <Paper
                                                elevation={0}
                                                sx={{
                                                    p: 1.5,
                                                    maxWidth: '75%',
                                                    borderRadius: 2,
                                                    bgcolor: 'white',
                                                    border: '1px solid #eee',
                                                }}
                                            >
                                                <Typography variant="caption" fontWeight={700} color="primary.main" gutterBottom display="block">
                                                    {msg.senderInfo?.firstName || 'Unknown'} {msg.senderInfo?.lastName || ''}
                                                </Typography>
                                                <Typography variant="body2">{msg.content}</Typography>
                                                <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5, display: 'block', textAlign: 'right' }}>
                                                    {new Date(msg.createdAt).toLocaleString()}
                                                </Typography>
                                            </Paper>
                                        </Box>
                                    ))
                                )}
                            </Box>
                        </>
                    )}
                </Card>
            </Box>
        </Box>
    );
};

export default Chats;
