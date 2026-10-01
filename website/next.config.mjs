const nextConfig = {
  images: {
    unoptimized: true,
  },
  async rewrites() {
    return [
      {
        source: "/track/open/:id",
        destination: "/api/track/open/:id",
      },
    ];
  },
};

export default nextConfig;
