import { ImageResponse } from "next/og";
import { readFile } from "fs/promises";
import { join } from "path";

export const alt = "hi-key — AI images from your keyboard";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default async function Image() {
  const nunitoBold = await readFile(
    join(process.cwd(), "src/assets/nunito-bold.ttf")
  );

  const wordmarkSvg = await readFile(
    join(process.cwd(), "public/hi-key.svg")
  );
  const wordmarkBase64 = `data:image/svg+xml;base64,${wordmarkSvg.toString("base64")}`;

  return new ImageResponse(
    (
      <div
        style={{
          display: "flex",
          width: "100%",
          height: "100%",
          backgroundColor: "#0F1115",
          padding: "80px 100px",
          alignItems: "center",
          justifyContent: "space-between",
        }}
      >
        {/* Left: text */}
        <div
          style={{ display: "flex", flexDirection: "column", maxWidth: 550 }}
        >
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={wordmarkBase64}
            alt="hi-key"
            width={280}
            height={101}
            style={{ objectFit: "contain" }}
          />
          <div
            style={{
              fontSize: 32,
              fontFamily: "Nunito",
              fontWeight: 700,
              color: "#9AA1AD",
              marginTop: 16,
              lineHeight: 1.4,
            }}
          >
            AI images from your keyboard
          </div>
          <div
            style={{
              width: 80,
              height: 4,
              backgroundColor: "#E4FF97",
              borderRadius: 2,
              marginTop: 24,
            }}
          />
          <div
            style={{
              fontSize: 18,
              color: "#6E7482",
              fontFamily: "Nunito",
              marginTop: 24,
            }}
          >
            hi-key.ai
          </div>
        </div>

        {/* Right: phone mockup */}
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            width: 260,
            height: 470,
            backgroundColor: "#171A20",
            borderRadius: 40,
            border: "2px solid #2A2F3A",
            padding: "60px 24px 24px",
          }}
        >
          {/* 2x2 image grid */}
          <div
            style={{
              display: "flex",
              flexWrap: "wrap",
              gap: 8,
              width: "100%",
              justifyContent: "center",
            }}
          >
            {[0, 1, 2, 3].map((i) => (
              <div
                key={i}
                style={{
                  width: 96,
                  height: 96,
                  backgroundColor: "#1E222B",
                  borderRadius: 12,
                }}
              />
            ))}
          </div>
          {/* Input bar */}
          <div
            style={{
              width: "100%",
              height: 36,
              backgroundColor: "#1E222B",
              borderRadius: 12,
              marginTop: 20,
            }}
          />
        </div>
      </div>
    ),
    {
      ...size,
      fonts: [
        {
          name: "Nunito",
          data: nunitoBold,
          style: "normal",
          weight: 700,
        },
      ],
    }
  );
}
