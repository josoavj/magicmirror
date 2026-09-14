import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'image.pollinations.ai',
      },
      {
        protocol: 'https',
        hostname: 'samsonsurmesure.fr',
      },
      {
        protocol: 'https',
        hostname: 'images.unsplash.com',
      },
      {
        protocol: 'https',
        hostname: 'openweathermap.org',
      }
    ],
  },
};

export default nextConfig;
