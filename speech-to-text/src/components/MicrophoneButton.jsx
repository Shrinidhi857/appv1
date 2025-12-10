import './MicrophoneButton.css'

function MicrophoneButton({ isRecording, isConnected, onStart, onStop, disabled }) {
    const handleClick = () => {
        if (isRecording) {
            onStop()
        } else {
            onStart()
        }
    }

    return (
        <div className="mic-container">
            <button
                className={`mic-button ${isRecording ? 'recording' : ''} ${disabled ? 'disabled' : ''}`}
                onClick={handleClick}
                disabled={disabled}
                aria-label={isRecording ? 'Stop recording' : 'Start recording'}
            >
                {/* Ripple effect when recording */}
                {isRecording && (
                    <>
                        <div className="ripple ripple-1"></div>
                        <div className="ripple ripple-2"></div>
                        <div className="ripple ripple-3"></div>
                    </>
                )}

                {/* Microphone Icon */}
                <svg
                    className="mic-icon"
                    width="32"
                    height="32"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                >
                    {isRecording ? (
                        // Stop icon when recording
                        <rect x="6" y="6" width="12" height="12" rx="2" />
                    ) : (
                        // Microphone icon when not recording
                        <>
                            <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" />
                            <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
                            <line x1="12" y1="19" x2="12" y2="23" />
                            <line x1="8" y1="23" x2="16" y2="23" />
                        </>
                    )}
                </svg>

                {/* Connection indicator */}
                {isConnected && (
                    <div className="connection-indicator">
                        <div className="pulse-dot"></div>
                    </div>
                )}
            </button>
        </div>
    )
}

export default MicrophoneButton
