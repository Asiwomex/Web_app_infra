# Hyperframes Composition Brief: Web_app_infra

## Objective
Short launch-style brag video for Web_app_infra, a Terraform AWS infrastructure project.

## Output
- Composition directory: `brag-output/composition/`
- Rendered video: `brag-output/brag.mp4`
- Format: landscape — 1920x1080, 30fps
- Duration: 21.5s

## Source Material
- Project root: Web_app_infra (Terraform)
- Primary files read: README.md, Report.md, ARCHITECTURE_CHANGES.md, modules/*, environments/prod/main.tf, web_app_infra.png
- Product name: Web_app_infra
- Strongest claim: production-ready AWS infra, three isolated environments, no SSH / no open ports (SSM only)
- Key visual to show: web_app_infra.png architecture diagram (cropped above the footnotes)
- Copy that must appear verbatim:
  - `terraform apply` / `Apply complete!`
  - dev 10.0.0.0/22 · staging 10.0.4.0/22 · prod 10.0.8.0/22
  - t3.small / t3.medium / t3.large; ASG 1–2 / 2–4 / 2–6
  - Route 53 → WAF → ALB → EC2 Auto Scaling → RDS primary + replica
  - No SSH. No open ports. No key pairs.

## Creative Direction
- Tone preset: polished; direction: quiet confident infra flex, terminal-to-cloud
- Hook: `terraform apply` types itself; `Apply complete!`
- Outro: "Web_app_infra — Production-grade AWS, written in Terraform." + 11 modules · 3 environments · 0 open admin ports
- Avoid: generic SaaS language, abstract filler, any secrets/IDs/domains/emails

## Visual Identity
- Background #0B1220, text #E8EDF5, accent #FF9900, flow red #E8636B, success #3FB950
- Display: Montserrat 900; body/code: JetBrains Mono 400/700 (both embedded by Hyperframes)

## Storyboard
See brag-plan.md. Scenes: Hook 0–3.27 · Environments 3.27–8.74 · Request path 8.74–13.11 · No SSH 13.11–17.47 · Outro 17.47–21.5.

## Audio
- Music: assets/music/happy-beats-business-moves-vol-12-by-ende-dot-app.mp3 at 0.32, fade last 1.2s
- Cue source: bundled preset (vol-12). Beat locks: 8.74, 13.11, 17.47.
- Audio-reactive: subtle bass-driven glow on outro + diagram frame.
- SFX: keyboard ticks, one click, soft drops, soft impacts, one bell. Chosen from sfx-analysis low/medium HF-risk picks.

## Hyperframes Instructions
Use hyperframes-core/animation/creative/keyframes/cli conventions; GSAP served locally from assets/vendor; run `npx hyperframes check` before render.
