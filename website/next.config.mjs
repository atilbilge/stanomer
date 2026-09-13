/** @type {import('next').NextConfig} */
const nextConfig = {
  // Disable image optimization for static export / custom hosting
  images: {
    unoptimized: true,
  },
  async rewrites() {
    return [
      {
        source: '/dev-app',
        destination: '/dev-app/index.html',
      },
      {
        source: '/dev-app/:path*',
        destination: '/dev-app/index.html',
      },
      {
        source: '/app',
        destination: '/app/index.html',
      },
      {
        source: '/app/:path*',
        destination: '/app/index.html',
      },
    ];
  },
};

export default nextConfig;

