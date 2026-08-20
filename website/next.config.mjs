/** @type {import('next').NextConfig} */
const nextConfig = {
  // Disable image optimization for static export / custom hosting
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
