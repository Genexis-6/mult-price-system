import os
from typing import Dict, List, Optional
from mailjet_rest import Client
from core.utils.logger import get_logger
from core.config import settings

logger = get_logger(__name__)

class EmailService:
    def __init__(self):
        # Get Mailjet credentials from settings
        self.api_key = settings.MAIL_JET_API
        self.api_secret = settings.MAIL_JET_SK
        self.sender_email = settings.APP_EMAIL_SENDER
        self.sender_name = "Mula Search"
        
        logger.info(f"Initializing Mailjet with API key: {self.api_key[:10]}...")
        
        # Initialize Mailjet client
        self.mailjet = Client(
            auth=(self.api_key, self.api_secret),
            version='v3.1'
        )
    
    async def send_price_alert_with_comparison(
        self,
        email: str,
        product_name: str,
        target_price: float,
        best_price: float,
        best_platform: str,
        best_url: str,
        all_platform_prices: Dict[str, Dict],  # This is a dict of dicts now
        savings: float,
        savings_percentage: float
    ):
        """Send price alert email with comparison across all platforms"""
        
        subject = f"🎯 Price Alert: {product_name} is now ₦{best_price:,.0f}!"
        
        # Create platform comparison table HTML
        platform_rows = ""
        platform_icons = {
            "jumia": "🛍️",
            "konga": "🛒", 
            "jiji": "📱"
        }
        
        for platform, data in all_platform_prices.items():
            # Extract price from the dictionary
            price = data['price'] if isinstance(data, dict) else data
            is_best = platform == best_platform
            
            platform_rows += f"""
            <tr style="{'background: #e8f5e9' if is_best else ''}">
                <td style="padding: 12px; border-bottom: 1px solid #e5e7eb;">
                    {platform_icons.get(platform, '🛍️')} {platform.upper()}
                </td>
                <td style="padding: 12px; border-bottom: 1px solid #e5e7eb;">
                    <div style="display: flex; align-items: center; gap: 12px;">
                        <img src="{data.get('image_url', '')}" style="width: 50px; height: 50px; object-fit: cover; border-radius: 8px;" onerror="this.style.display='none'">
                        <div>
                            <div><strong>{data.get('product_name', product_name)}</strong></div>
                            <div style="color: {'#10b981' if is_best else '#666'}">
                                {'<strong>₦{price:,.0f}</strong>' if is_best else f'₦{price:,.0f}'}
                            </div>
                        </div>
                    </div>
                </td>
                <td style="padding: 12px; border-bottom: 1px solid #e5e7eb; text-align: center;">
                    {'🏆 BEST' if is_best else ''}
                    <a href="{data.get('url', '#')}" style="display: block; font-size: 12px; margin-top: 4px;">View →</a>
                </td>
            </tr>
            """
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                           color: white; padding: 30px; text-align: center; border-radius: 12px 12px 0 0; }}
                .price {{ font-size: 36px; font-weight: bold; color: #10b981; }}
                .savings {{ font-size: 24px; color: #ef4444; }}
                .button {{ background: #667eea; color: white; padding: 12px 24px; 
                          text-decoration: none; border-radius: 8px; display: inline-block; }}
                table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
                th {{ background: #f3f4f6; padding: 12px; text-align: left; }}
                .footer {{ background: #f3f4f6; padding: 20px; text-align: center; font-size: 12px; color: #6b7280; border-radius: 0 0 12px 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🎉 Price Alert Triggered!</h1>
                    <p>Great news about your tracked product</p>
                </div>
                
                <div style="padding: 30px;">
                    <h2>{product_name}</h2>
                    
                    <div class="price">₦{best_price:,.0f}</div>
                    <p>Your target price was <strong>₦{target_price:,.0f}</strong></p>
                    
                    <div class="savings">
                        🎯 You save ₦{savings:,.0f} ({savings_percentage:.1f}%)
                    </div>
                    
                    <h3>📊 Price Comparison Across Platforms</h3>
                    <table>
                        <thead>
                            <tr>
                                <th>Platform</th>
                                <th>Product</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            {platform_rows}
                        </tbody>
                    </table>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{best_url}" class="button">View Best Deal on {best_platform.upper()} →</a>
                    </div>
                    
                    <div style="background: #fef3c7; padding: 16px; border-radius: 8px; margin: 20px 0;">
                        <p style="margin: 0; color: #92400e;">
                            💡 <strong>Pro Tip:</strong> Check the product listing quickly as prices may change!
                        </p>
                    </div>
                </div>
                
                <div class="footer">
                    <p>You're receiving this email because you set a price alert on Mula Search.</p>
                    <p><a href="#">Manage Alerts</a> | <a href="#">Unsubscribe</a></p>
                    <p style="margin-top: 16px;">© 2025 Mula Search. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        await self._send_email(email, subject, html_content)
    
    async def send_welcome_email(self, email: str):
        """Send welcome email to new user"""
        subject = "Welcome to Mula Search Price Tracking! 🚀"
        
        html_content = self._get_welcome_email_html()
        
        await self._send_email(email, subject, html_content)
    
    async def send_test_email(self, email: str):
        """Send a simple test email to verify configuration"""
        subject = "Mula Search - Test Email"
        
        html_content = """
        <!DOCTYPE html>
        <html>
        <head><title>Test Email</title></head>
        <body>
            <h1>Mula Search Test Email</h1>
            <p>If you're receiving this, your email configuration is working!</p>
            <p>Price tracking alerts will now be sent to this address.</p>
        </body>
        </html>
        """
        
        await self._send_email(email, subject, html_content)
    
    async def _send_email(self, to_email: str, subject: str, html_content: str):
        """Send email using Mailjet API"""
        
        if not self.api_key or not self.api_secret:
            logger.error("Mailjet credentials not configured!")
            return {"error": "Mailjet credentials not configured"}
        
        try:
            data = {
                'Messages': [
                    {
                        "From": {
                            "Email": self.sender_email,
                            "Name": self.sender_name
                        },
                        "To": [
                            {
                                "Email": to_email,
                                "Name": "Valued Customer"
                            }
                        ],
                        "Subject": subject,
                        "HTMLPart": html_content,
                        "TextPart": "Price alert notification",
                        "CustomID": f"price_alert_{to_email}"
                    }
                ]
            }
            
            logger.info(f"Sending email to {to_email}")
            
            result = self.mailjet.send.create(data=data)
            
            logger.info(f"Mailjet response status: {result.status_code}")
            
            if result.status_code == 200:
                logger.info(f"✅ Email sent successfully to {to_email}")
                return {"success": True, "data": result.json()}
            else:
                logger.error(f"❌ Failed to send email: {result.status_code} - {result.text}")
                return {"success": False, "error": result.text}
                
        except Exception as e:
            logger.error(f"❌ Mailjet error: {e}")
            import traceback
            logger.error(traceback.format_exc())
            return {"success": False, "error": str(e)}
    
    def _get_welcome_email_html(self):
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                           color: white; padding: 30px; text-align: center; border-radius: 12px 12px 0 0; }}
                .features {{ display: flex; justify-content: space-around; margin: 30px 0; }}
                .feature {{ text-align: center; padding: 20px; }}
                .feature-icon {{ font-size: 48px; }}
                .footer {{ background: #f3f4f6; padding: 20px; text-align: center; font-size: 12px; color: #6b7280; border-radius: 0 0 12px 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Welcome to Mula Search! 🚀</h1>
                    <p>Your personal price tracking assistant</p>
                </div>
                
                <div style="padding: 30px;">
                    <h2>Hi there! 👋</h2>
                    <p>Thanks for signing up for price alerts on Mula Search!</p>
                    
                    <div class="features">
                        <div class="feature">
                            <div class="feature-icon">🔍</div>
                            <h3>Track Products</h3>
                            <p>Monitor prices across Jumia, Konga, and Jiji</p>
                        </div>
                        <div class="feature">
                            <div class="feature-icon">📧</div>
                            <h3>Email Alerts</h3>
                            <p>Get notified when prices drop</p>
                        </div>
                        <div class="feature">
                            <div class="feature-icon">💰</div>
                            <h3>Save Money</h3>
                            <p>Never miss a good deal again</p>
                        </div>
                    </div>
                    
                    <div style="background: #e8f5e9; padding: 16px; border-radius: 8px; margin: 20px 0;">
                        <p style="margin: 0; color: #2e7d32;">
                            ✅ You're all set! We'll start monitoring prices for your tracked products immediately.
                        </p>
                    </div>
                </div>
                
                <div class="footer">
                    <p>© 2025 Mula Search. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """