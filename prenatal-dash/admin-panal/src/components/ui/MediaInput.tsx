import React, { useState, useRef } from 'react';
import { Upload, Link as LinkIcon, X, Loader2, Video, FileText, ExternalLink } from 'lucide-react';
import { cmsClient } from '../../services/api';

interface MediaInputProps {
    label?: string;
    value: string;
    onChange: (url: string) => void;
    type?: 'image' | 'video' | 'pdf' | 'media';
    placeholder?: string;
    helpText?: string;
}

export function MediaInput({
    label,
    value,
    onChange,
    type = 'image',
    placeholder,
    helpText,
}: MediaInputProps) {
    const [uploading, setUploading] = useState(false);
    const [uploadError, setUploadError] = useState<string | null>(null);
    const [mode, setMode] = useState<'url' | 'upload'>('url');
    const fileInputRef = useRef<HTMLInputElement>(null);

    const isImage = type === 'image' || (type === 'media' && (value.match(/\.(jpg|jpeg|png|webp|gif|svg)$/i) || !value.match(/\.(mp4|webm|pdf)$/i)));
    const isVideo = type === 'video' || value.match(/\.(mp4|webm|mov|m4v)$/i) || value.includes('youtube.com') || value.includes('youtu.be');
    const isPdf = type === 'pdf' || value.match(/\.pdf$/i);

    const acceptTypes =
        type === 'image' ? 'image/*' :
        type === 'video' ? 'video/*' :
        type === 'pdf' ? 'application/pdf,.pdf' :
        'image/*,video/*,application/pdf,.pdf';

    const defaultPlaceholder =
        type === 'image' ? 'https://example.com/image.jpg or /uploads/...' :
        type === 'video' ? 'https://youtube.com/... or /uploads/video.mp4' :
        type === 'pdf' ? 'https://example.com/guide.pdf or /uploads/...' :
        'Media URL...';

    async function handleFileSelected(e: React.ChangeEvent<HTMLInputElement>) {
        const file = e.target.files?.[0];
        if (!file) return;

        try {
            setUploading(true);
            setUploadError(null);
            const res = await cmsClient.upload(file);
            onChange(res.url);
        } catch (err: any) {
            console.error('Upload failed:', err);
            setUploadError(err.message || 'File upload failed');
        } finally {
            setUploading(false);
            if (fileInputRef.current) {
                fileInputRef.current.value = '';
            }
        }
    }

    return (
        <div className="flex flex-col gap-1.5">
            {label && (
                <div className="flex items-center justify-between">
                    <label className="text-xs font-semibold text-gray-700 uppercase tracking-wide">
                        {label}
                    </label>
                    <div className="flex items-center gap-1 text-xs">
                        <button
                            type="button"
                            onClick={() => setMode('url')}
                            className={`px-2 py-0.5 rounded transition-colors ${mode === 'url' ? 'bg-[#61183e] text-white font-medium' : 'text-gray-500 hover:text-gray-800'}`}
                        >
                            URL
                        </button>
                        <button
                            type="button"
                            onClick={() => setMode('upload')}
                            className={`px-2 py-0.5 rounded transition-colors ${mode === 'upload' ? 'bg-[#61183e] text-white font-medium' : 'text-gray-500 hover:text-gray-800'}`}
                        >
                            Upload File
                        </button>
                    </div>
                </div>
            )}

            {/* Input Controls */}
            {mode === 'url' ? (
                <div className="relative flex items-center">
                    <div className="absolute left-3 text-gray-400 pointer-events-none">
                        {isPdf ? <FileText className="w-4 h-4" /> : isVideo ? <Video className="w-4 h-4" /> : <LinkIcon className="w-4 h-4" />}
                    </div>
                    <input
                        type="text"
                        value={value}
                        onChange={e => onChange(e.target.value)}
                        placeholder={placeholder || defaultPlaceholder}
                        className="w-full pl-9 pr-8 py-2 text-sm border border-gray-200 rounded-xl bg-white focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/10 transition"
                    />
                    {value && (
                        <button
                            type="button"
                            onClick={() => onChange('')}
                            className="absolute right-2.5 text-gray-400 hover:text-gray-600 p-0.5"
                            title="Clear"
                        >
                            <X className="w-3.5 h-3.5" />
                        </button>
                    )}
                </div>
            ) : (
                <div className="flex items-center gap-2">
                    <input
                        type="file"
                        ref={fileInputRef}
                        onChange={handleFileSelected}
                        accept={acceptTypes}
                        className="hidden"
                    />
                    <button
                        type="button"
                        onClick={() => fileInputRef.current?.click()}
                        disabled={uploading}
                        className="flex-1 flex items-center justify-center gap-2 px-4 py-2 border-2 border-dashed border-gray-200 hover:border-[#61183e] rounded-xl text-sm font-medium text-gray-700 hover:text-[#61183e] bg-gray-50 hover:bg-[#fdf2f8]/40 transition disabled:opacity-60 cursor-pointer"
                    >
                        {uploading ? (
                            <>
                                <Loader2 className="w-4 h-4 animate-spin text-[#61183e]" />
                                <span>Uploading locally...</span>
                            </>
                        ) : (
                            <>
                                <Upload className="w-4 h-4 text-[#61183e]" />
                                <span>Browse &amp; Upload {type === 'pdf' ? 'PDF File' : type === 'video' ? 'Video File' : 'Image File'}</span>
                            </>
                        )}
                    </button>
                </div>
            )}

            {uploadError && (
                <p className="text-xs text-red-500 font-medium mt-0.5">{uploadError}</p>
            )}

            {/* Preview Section */}
            {value && (
                <div className="flex items-center justify-between gap-3 p-2.5 bg-gray-50 border border-gray-100 rounded-xl mt-1 text-xs">
                    <div className="flex items-center gap-2.5 min-w-0 flex-1">
                        {isImage ? (
                            <img
                                src={value}
                                alt="Preview"
                                className="w-10 h-10 rounded-lg object-cover border border-gray-200 shrink-0 bg-white"
                                onError={(e) => {
                                    // fallback icon if image fails to load
                                    (e.target as HTMLElement).style.display = 'none';
                                }}
                            />
                        ) : isVideo ? (
                            <div className="w-10 h-10 rounded-lg bg-purple-50 text-purple-600 flex items-center justify-center shrink-0 border border-purple-100">
                                <Video className="w-5 h-5" />
                            </div>
                        ) : (
                            <div className="w-10 h-10 rounded-lg bg-red-50 text-red-600 flex items-center justify-center shrink-0 border border-red-100">
                                <FileText className="w-5 h-5" />
                            </div>
                        )}
                        <div className="min-w-0 flex-1">
                            <p className="font-medium text-gray-800 truncate" title={value}>
                                {value.split('/').pop() || value}
                            </p>
                            <p className="text-gray-400 font-mono truncate text-[11px]">{value}</p>
                        </div>
                    </div>
                    <div className="flex items-center gap-1 shrink-0">
                        <a
                            href={value}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="p-1 text-gray-400 hover:text-[#61183e] rounded hover:bg-white transition"
                            title="Open Link in New Tab"
                        >
                            <ExternalLink className="w-3.5 h-3.5" />
                        </a>
                        <button
                            type="button"
                            onClick={() => onChange('')}
                            className="p-1 text-red-400 hover:text-red-600 rounded hover:bg-white transition"
                            title="Remove"
                        >
                            <X className="w-3.5 h-3.5" />
                        </button>
                    </div>
                </div>
            )}

            {helpText && (
                <span className="text-[11px] text-gray-400">{helpText}</span>
            )}
        </div>
    );
}
