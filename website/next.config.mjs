/** @type {import('next').NextConfig} */
const nextConfig = {
  // We removed 'output: export' to support Server Actions for Notion integration

  // Disable image optimization for static export
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
