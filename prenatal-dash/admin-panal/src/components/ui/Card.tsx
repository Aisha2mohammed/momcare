import React from 'react';
import clsx from 'clsx';

interface CardProps {
    children: React.ReactNode;
    className?: string;
}

export function Card({ children, className }: CardProps) {
    return (
        <div className={clsx('bg-white rounded-2xl shadow-xs border border-rose-50/80 p-4 sm:p-6 min-w-0', className)}>
            {children}
        </div>
    );
}
