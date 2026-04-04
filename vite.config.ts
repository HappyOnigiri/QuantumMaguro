import { resolve } from "node:path";
import { type Plugin, defineConfig } from "vite";

function generateRobotsPlugin(): Plugin {
	return {
		name: "generate-robots-txt",
		generateBundle() {
			this.emitFile({
				type: "asset",
				fileName: "robots.txt",
				source: "User-agent: *\nAllow: /\n",
			});
		},
		configureServer(server) {
			server.middlewares.use((req, res, next) => {
				if (req.url === "/robots.txt") {
					res.setHeader("Content-Type", "text/plain");
					res.end("User-agent: *\nAllow: /\n");
					return;
				}
				next();
			});
		},
	};
}

function resolveSharedAliasPlugin(): Plugin {
	return {
		name: "resolve-shared-alias",
		enforce: "pre",
		transformIndexHtml: {
			order: "pre",
			handler(html: string) {
				// @shared/ を /src/assets/shared/ に置換（index.html の src/srcset/href/data-src 属性）
				return html.replace(
					/(src|srcset|href|data-src)=("|'|`)(.*?)@shared\/(.*?)\2/g,
					(match, attr, quote, p1, p2) => {
						const value = `${p1}@shared/${p2}`;
						return `${attr}=${quote}${value.replace(/@shared\//g, "/src/assets/shared/")}${quote}`;
					},
				);
			},
		},
	};
}

export default defineConfig({
	resolve: {
		alias: {
			"@shared": resolve(__dirname, "src/assets/shared"),
			"@shared-ts": resolve(__dirname, "src/shared"),
		},
	},
	plugins: [generateRobotsPlugin(), resolveSharedAliasPlugin()],
	server: {
		port: 5181,
	},
	build: {
		rollupOptions: {
			input: {
				main: resolve(__dirname, "index.html"),
			},
		},
	},
});
