# 🛍️ The Awesome Store

Welcome to the most minimalist product store you'll ever lay eyes on! This is a Rails 8.1 powered web app where products come to live, breathe, and occasionally get deleted (RIP little products).

## 🎯 What Does This Thing Do?

Ever wanted to manage products without all the fancy bells and whistles? Well, congratulations, you found it! This app lets you:

- 📝 **Create products** - Give birth to new products with just a name (because who needs descriptions anyway?)
- 👀 **View products** - Gaze upon your magnificent product collection
- ✏️ **Edit products** - Made a typo? Changed your mind? We got you covered!
- 💥 **Delete products** - Sometimes products just need to... go away

It's like a shopping cart, but without the shopping, the cart, or the payment processing. Just pure, unadulterated product management bliss.

## 🎨 What's Under the Hood?

This bad boy is rocking:
- **Rails 8.1** - Fresh off the press!
- **SQLite3** - Because we like to keep it simple
- **Tailwind CSS** - Making things pretty without trying too hard
- **Hotwire** (Turbo + Stimulus) - For that SPA-like feel without the JavaScript fatigue
- **Solid Queue, Cache & Cable** - The holy trinity of solid-ness

## 🚀 Getting Started

### Prerequisites

You'll need:
- Ruby (the version that Rails 8.1 likes)
- A terminal (preferably one that doesn't judge you)
- Coffee (not technically required, but highly recommended)

### Installation

1. **Clone this beauty:**
   ```bash
   git clone <your-repo-url>
   cd store
   ```

2. **Install the gems:**
   ```bash
   bundle install
   ```

3. **Set up the database:**
   ```bash
   bin/rails db:create db:migrate
   ```
   
   This creates a SQLite database and adds a `products` table with:
   - `name` (string) - The only thing we care about
   - `created_at` & `updated_at` (timestamps) - Rails magic ✨

4. **Seed some data (optional):**
   ```bash
   bin/rails db:seed
   ```

### 🏃‍♂️ Running the App

Fire up the development server with style:

```bash
bin/dev
```

This starts:
- The Rails server (port 3000)
- The Tailwind CSS watcher (keeping things fresh)

Then point your browser to `http://localhost:3000` and behold your product empire!

## 🧪 Testing

Run the test suite to make sure everything is working:

```bash
bin/rails test
```

We've got tests for:
- The Products controller (create, read, update, destroy)
- The Product model (because even simple models deserve validation)

## 📁 Key Files to Know

- **Routes:** [config/routes.rb](config/routes.rb) - Where the magic URL mapping happens
- **Product Model:** [app/models/product.rb](app/models/product.rb) - The mighty Product class (all 3 lines of it)
- **Products Controller:** [app/controllers/products_controller.rb](app/controllers/products_controller.rb) - CRUD operations galore
- **Views:** [app/views/products/](app/views/products/) - The HTML that makes your browser happy

## 🐳 Docker Support

Feeling fancy? We've got Docker support:

```bash
docker build -t awesome-store .
docker run -p 3000:3000 awesome-store
```

## 🚢 Deployment

This app comes with Kamal deployment support out of the box! Just configure your [config/deploy.yml](config/deploy.yml) and:

```bash
kamal deploy
```

## 🤔 Common Issues

**Q: Why can't I create a product without a name?**  
A: Because we have *standards*. The Product model validates presence of name. Empty names are so last decade.

**Q: Where are the prices, descriptions, and images?**  
A: In your imagination! This is the MVP of MVPs. Fork it and add them yourself!

## 📚 Learning Resources

This project was built as part of The Odin Project curriculum. Perfect for:
- Learning Rails CRUD operations
- Understanding RESTful routing
- Getting comfortable with Hotwire
- Appreciating the beauty of simplicity

## 🎉 Contributing

Found a bug? Want to add features? PRs welcome! Just remember: keep it simple, keep it fun.

## 📄 License

This project is open source and available under the [MIT License](https://opensource.org/licenses/MIT).

---

Made with ❤️ and way too much coffee by someone learning Rails
