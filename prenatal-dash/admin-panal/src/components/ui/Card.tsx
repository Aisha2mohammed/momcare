import React from 'react';
import clsx from 'clsx';

interface CardProps {
    children: React.ReactNode;
    className?: string;
}

export function Card({ children, className }: CardProps) {
    return (
        <div className={clsx('bg-white rounded-2xl shadow-sm border border-rose-50 p-6', className)}>
            {children}
        </div>
    );
}
