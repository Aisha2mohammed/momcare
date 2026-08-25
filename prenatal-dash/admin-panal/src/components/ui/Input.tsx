import React from 'react';
import clsx from 'clsx';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
    label?: string;
    error?: string;
}

export function Input({ label, error, className, id, ...props }: InputProps) {
    return (
        <div className="flex flex-col gap-1">
            {label && <label htmlFor={id} className="text-sm font-medium text-gray-700">{label}</label>}
            <input
                id={id}
                {...props}
                className={clsx(
                    'w-full px-3 py-2 rounded-lg border text-sm bg-white outline-none transition',
                    'border-gray-200 placeholder-gray-400 text-gray-900',
                    'focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20',
                    error && 'border-red-400',
                    className
                )}
            />
            {error && <span className="text-xs text-red-500">{error}</span>}
        </div>
    );
}

interface SelectProps extends React.SelectHTMLAttributes<HTMLSelectElement> {
    label?: string;
    error?: string;
    options: { value: string; label: string }[];
}

export function Select({ label, error, options, id, className, ...props }: SelectProps) {
    return (
        <div className="flex flex-col gap-1">
            {label && <label htmlFor={id} className="text-sm font-medium text-gray-700">{label}</label>}
            <select
                id={id}
                {...props}
                className={clsx(
                    'w-full px-3 py-2 rounded-lg border text-sm bg-white outline-none transition',
                    'border-gray-200 text-gray-900',
                    'focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20',
                    error && 'border-red-400',
                    className
                )}
            >
                {options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
            {error && <span className="text-xs text-red-500">{error}</span>}
        </div>
    );
}

interface TextAreaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
    label?: string;
    error?: string;
}

export function TextArea({ label, error, id, className, ...props }: TextAreaProps) {
    return (
        <div className="flex flex-col gap-1">
            {label && <label htmlFor={id} className="text-sm font-medium text-gray-700">{label}</label>}
            <textarea
                id={id}
                {...props}
                className={clsx(
                    'w-full px-3 py-2 rounded-lg border text-sm bg-white outline-none transition resize-y',
                    'border-gray-200 placeholder-gray-400 text-gray-900',
                    'focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20',
                    error && 'border-red-400',
                    className
                )}
            />
            {error && <span className="text-xs text-red-500">{error}</span>}
        </div>
    );
}
