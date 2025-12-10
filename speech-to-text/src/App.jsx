import { useState, useEffect, useRef } from 'react'
import './App.css'
import MicrophoneButton from './components/MicrophoneButton'
import TranscriptionDisplay from './components/TranscriptionDisplay'

function App() {
    const [apiKey, setApiKey] = useState(null)
    const [isRecording, setIsRecording] = useState(false)
    const [transcription, setTranscription] = useState([])
    const [interimText, setInterimText] = useState('')
    const [error, setError] = useState(null)
    const [isConnected, setIsConnected] = useState(false)

    const mediaRecorderRef = useRef(null)
    const socketRef = useRef(null)
    const audioChunksRef = useRef([])

    // Listen for API key from Flutter via postMessage
    useEffect(() => {
        const handleMessage = (event) => {
            console.log('Received message:', event.data)

            if (event.data && event.data.type === 'DEEPGRAM_API_KEY') {
                console.log('API key received from Flutter')
                setApiKey(event.data.apiKey)
                setError(null)
            }
        }

        window.addEventListener('message', handleMessage)

        // Request API key from Flutter
        if (window.ReactNativeWebView) {
            window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'REQUEST_API_KEY' }))
        } else {
            // For testing in browser, check for test key
            const testKey = localStorage.getItem('DEEPGRAM_API_KEY')
            if (testKey) {
                setApiKey(testKey)
            } else {
                setError('Running in browser mode. Please set API key in localStorage with key "DEEPGRAM_API_KEY"')
            }
        }

        return () => window.removeEventListener('message', handleMessage)
    }, [])

    const startRecording = async () => {
        if (!apiKey) {
            setError('API key not available. Please wait...')
            return
        }

        try {
            setError(null)
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true })

            // Initialize Deepgram WebSocket connection
            const socket = new WebSocket(
                'wss://api.deepgram.com/v1/listen?encoding=linear16&sample_rate=16000&language=en-US&model=nova-2',
                ['token', apiKey]
            )

            socket.onopen = () => {
                console.log('Deepgram connection opened')
                setIsConnected(true)
                setIsRecording(true)
            }

            socket.onmessage = (message) => {
                const data = JSON.parse(message.data)

                if (data.channel && data.channel.alternatives && data.channel.alternatives[0]) {
                    const transcript = data.channel.alternatives[0].transcript

                    if (transcript && transcript.trim() !== '') {
                        if (data.is_final) {
                            setTranscription(prev => [...prev, transcript])
                            setInterimText('')
                        } else {
                            setInterimText(transcript)
                        }
                    }
                }
            }

            socket.onerror = (error) => {
                console.error('WebSocket error:', error)
                setError('Connection error. Please check your API key.')
                stopRecording()
            }

            socket.onclose = () => {
                console.log('Deepgram connection closed')
                setIsConnected(false)
            }

            socketRef.current = socket

            // Set up MediaRecorder to send audio to Deepgram
            const mediaRecorder = new MediaRecorder(stream, {
                mimeType: 'audio/webm'
            })

            mediaRecorder.ondataavailable = (event) => {
                if (event.data.size > 0 && socket.readyState === WebSocket.OPEN) {
                    socket.send(event.data)
                }
            }

            mediaRecorder.start(250) // Send data every 250ms
            mediaRecorderRef.current = mediaRecorder

        } catch (err) {
            console.error('Error starting recording:', err)
            setError('Microphone access denied. Please allow microphone permissions.')
        }
    }

    const stopRecording = () => {
        if (mediaRecorderRef.current && mediaRecorderRef.current.state !== 'inactive') {
            mediaRecorderRef.current.stop()
            mediaRecorderRef.current.stream.getTracks().forEach(track => track.stop())
        }

        if (socketRef.current && socketRef.current.readyState === WebSocket.OPEN) {
            socketRef.current.close()
        }

        setIsRecording(false)
        setIsConnected(false)
    }

    const clearTranscription = () => {
        setTranscription([])
        setInterimText('')
    }

    return (
        <div className="app">
            {/* Header */}
            <header className="header">
                <div className="logo">
                    <span className="logo-text">HandSpeaks</span>
                    <span className="logo-badge">PRO</span>
                </div>
                <h1 className="title">Speech to Text</h1>
                <p className="subtitle">Speak clearly into your microphone</p>
            </header>

            {/* Main Content */}
            <main className="main-content">
                {/* Error Display */}
                {error && (
                    <div className="error-banner fade-in">
                        <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
                            <path d="M10 0C4.48 0 0 4.48 0 10C0 15.52 4.48 20 10 20C15.52 20 20 15.52 20 10C20 4.48 15.52 0 10 0ZM11 15H9V13H11V15ZM11 11H9V5H11V11Z" fill="currentColor" />
                        </svg>
                        <span>{error}</span>
                    </div>
                )}

                {/* Transcription Display */}
                <TranscriptionDisplay
                    transcription={transcription}
                    interimText={interimText}
                    onClear={clearTranscription}
                />

                {/* Microphone Button */}
                <MicrophoneButton
                    isRecording={isRecording}
                    isConnected={isConnected}
                    onStart={startRecording}
                    onStop={stopRecording}
                    disabled={!apiKey}
                />

                {/* Status Indicator */}
                <div className="status-text">
                    {!apiKey ? (
                        <span className="status-waiting">Waiting for API key...</span>
                    ) : isRecording ? (
                        <span className="status-recording">● Recording</span>
                    ) : (
                        <span className="status-ready">Tap to start recording</span>
                    )}
                </div>
            </main>

            {/* Footer Info */}
            <footer className="footer">
                <p className="footer-text">Powered by Deepgram</p>
            </footer>
        </div>
    )
}

export default App
