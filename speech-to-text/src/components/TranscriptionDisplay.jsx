import './TranscriptionDisplay.css'

function TranscriptionDisplay({ transcription, interimText, onClear }) {
    const hasContent = transcription.length > 0 || interimText

    return (
        <div className="transcription-container">
            <div className="transcription-header">
                <h2 className="transcription-title">Transcription</h2>
                {hasContent && (
                    <button className="clear-button" onClick={onClear} aria-label="Clear transcription">
                        <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                            <path
                                d="M2 4H14M6 4V2.5C6 2.22386 6.22386 2 6.5 2H9.5C9.77614 2 10 2.22386 10 2.5V4M12.5 4V13C12.5 13.5523 12.0523 14 11.5 14H4.5C3.94772 14 3.5 13.5523 3.5 13V4"
                                stroke="currentColor"
                                strokeWidth="1.5"
                                strokeLinecap="round"
                                strokeLinejoin="round"
                            />
                        </svg>
                        Clear
                    </button>
                )}
            </div>

            <div className="transcription-content glass">
                {!hasContent ? (
                    <div className="empty-state">
                        <svg width="48" height="48" viewBox="0 0 48 48" fill="none" opacity="0.3">
                            <path
                                d="M24 4C22.3431 4 21 5.34315 21 7V25C21 26.6569 22.3431 28 24 28C25.6569 28 27 26.6569 27 25V7C27 5.34315 25.6569 4 24 4Z"
                                fill="currentColor"
                            />
                            <path
                                d="M14 20V25C14 30.5228 18.4772 35 24 35C29.5228 35 34 30.5228 34 25V20"
                                stroke="currentColor"
                                strokeWidth="3"
                                strokeLinecap="round"
                            />
                            <path d="M24 35V44M18 44H30" stroke="currentColor" strokeWidth="3" strokeLinecap="round" />
                        </svg>
                        <p className="empty-text">Your transcription will appear here</p>
                    </div>
                ) : (
                    <div className="transcription-text">
                        {/* Final transcriptions */}
                        {transcription.map((text, index) => (
                            <p key={index} className="final-text fade-in">
                                {text}
                            </p>
                        ))}

                        {/* Interim transcription */}
                        {interimText && (
                            <p className="interim-text">
                                {interimText}
                            </p>
                        )}
                    </div>
                )}
            </div>

            {/* Word count */}
            {transcription.length > 0 && (
                <div className="word-count">
                    {transcription.join(' ').split(' ').filter(word => word.trim() !== '').length} words
                </div>
            )}
        </div>
    )
}

export default TranscriptionDisplay
