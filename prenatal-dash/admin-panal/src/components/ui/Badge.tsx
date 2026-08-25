import clsx from 'clsx';

type Variant = 'green' | 'red' | 'yellow' | 'blue' | 'purple' | 'gray' | 'pink';
interface BadgeProps {
    children: React.ReactNode;
    variant?: Variant;
    className?: string;
}

const variantStyles: Record<Variant, string> = {
    green: 'bg-green-100 text-green-700',
    red: 'bg-red-100 text-red-700',
    yellow: 'bg-yellow-100 text-yellow-700',
    blue: 'bg-blue-100 text-blue-700',
    purple: 'bg-purple-100 text-purple-700',
    gray: 'bg-gray-100 text-gray-600',
    pink: 'bg-[#fdf2f8] text-[#61183e]',
};

export function Badge({ children, variant = 'gray', className }: BadgeProps) {
    return (
        <span className={clsx('inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium', variantStyles[variant], className)}>
            {children}
        </span>
    );
}
