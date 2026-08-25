import React from 'react';
import clsx from 'clsx';

type Variant = 'primary' | 'secondary' | 'danger' | 'ghost';
type Size = 'sm' | 'md' | 'lg';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
    variant?: Variant;
    size?: Size;
    children: React.ReactNode;
    icon?: React.ReactNode;
}

const variantStyles: Record<Variant, string> = {
    primary: 'bg-[#61183e] text-white hover:bg-[#7a1f4f] shadow-sm',
    secondary: 'bg-[#fdf2f8] text-[#61183e] border border-[#fbcfe8] hover:bg-[#fbcfe8]',
    danger: 'bg-red-100 text-red-700 hover:bg-red-200',
    ghost: 'text-gray-600 hover:bg-gray-100',
};

const sizeStyles: Record<Size, string> = {
    sm: 'px-3 py-1.5 text-xs',
    md: 'px-4 py-2 text-sm',
    lg: 'px-6 py-2.5 text-base',
};

export function Button({ variant = 'primary', size = 'md', children, icon, className, ...props }: ButtonProps) {
    return (
        <button
            {...props}
            className={clsx(
                'inline-flex items-center gap-2 font-medium rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-[#61183e] focus:ring-offset-1 disabled:opacity-50 disabled:cursor-not-allowed',
                variantStyles[variant],
                sizeStyles[size],
                className
            )}
        >
            {icon && <span>{icon}</span>}
            {children}
        </button>
    );
}
