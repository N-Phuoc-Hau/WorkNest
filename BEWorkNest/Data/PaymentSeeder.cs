using BEWorkNest.Models;
using Microsoft.EntityFrameworkCore;

namespace BEWorkNest.Data
{
    public static class PaymentSeeder
    {
        public static void SeedSubscriptionPlans(ApplicationDbContext context)
        {
            // Check if plans already exist
            if (context.SubscriptionPlans.Any())
            {
                Console.WriteLine("Subscription plans already seeded.");
                return;
            }

            var plans = new List<SubscriptionPlan>
            {
                new SubscriptionPlan
                {
                    Name = "Free",
                    Description = "Gói miễn phí - Dùng thử các tính năng cơ bản",
                    Price = 0,
                    DurationDays = 365,
                    Currency = "VND",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new SubscriptionPlan
                {
                    Name = "Basic",
                    Description = "Gói cơ bản - Phù hợp cho người tìm việc cá nhân",
                    Price = 99000,
                    DurationDays = 30,
                    Currency = "VND",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new SubscriptionPlan
                {
                    Name = "Pro",
                    Description = "Gói chuyên nghiệp - Dành cho người tìm việc nghiêm túc",
                    Price = 199000,
                    DurationDays = 30,
                    Currency = "VND",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new SubscriptionPlan
                {
                    Name = "Enterprise",
                    Description = "Gói doanh nghiệp - Giải pháp toàn diện cho nhà tuyển dụng",
                    Price = 499000,
                    DurationDays = 30,
                    Currency = "VND",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                }
            };

            context.SubscriptionPlans.AddRange(plans);
            context.SaveChanges();

            Console.WriteLine($"Seeded {plans.Count} subscription plans.");

            // Seed features for each plan
            SeedFeatures(context, plans);
        }

        private static void SeedFeatures(ApplicationDbContext context, List<SubscriptionPlan> plans)
        {
            var features = new List<SubscriptionFeature>();

            // Free plan features
            var freePlan = plans.FirstOrDefault(p => p.Name == "Free");
            if (freePlan != null)
            {
                features.AddRange(new[]
                {
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = freePlan.Id,
                        FeatureName = "max_applications",
                        FeatureValue = "5",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = freePlan.Id,
                        FeatureName = "cv_builder",
                        FeatureValue = "false",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = freePlan.Id,
                        FeatureName = "video_call",
                        FeatureValue = "false",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = freePlan.Id,
                        FeatureName = "cv_templates_premium",
                        FeatureValue = "false",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = freePlan.Id,
                        FeatureName = "priority_support",
                        FeatureValue = "false",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = freePlan.Id,
                        FeatureName = "cv_export_pdf",
                        FeatureValue = "false",
                        CreatedAt = DateTime.UtcNow
                    }
                });
            }

            // Basic plan features
            var basicPlan = plans.FirstOrDefault(p => p.Name == "Basic");
            if (basicPlan != null)
            {
                features.AddRange(new[]
                {
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = basicPlan.Id,
                        FeatureName = "max_applications",
                        FeatureValue = "50",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = basicPlan.Id,
                        FeatureName = "cv_builder",
                        FeatureValue = "true",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = basicPlan.Id,
                        FeatureName = "video_call",
                        FeatureValue = "false",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = basicPlan.Id,
                        FeatureName = "cv_templates_premium",
                        FeatureValue = "false",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = basicPlan.Id,
                        FeatureName = "priority_support",
                        FeatureValue = "false",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = basicPlan.Id,
                        FeatureName = "cv_export_pdf",
                        FeatureValue = "true",
                        CreatedAt = DateTime.UtcNow
                    }
                });
            }

            // Pro plan features
            var proPlan = plans.FirstOrDefault(p => p.Name == "Pro");
            if (proPlan != null)
            {
                features.AddRange(new[]
                {
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = proPlan.Id,
                        FeatureName = "max_applications",
                        FeatureValue = "unlimited",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = proPlan.Id,
                        FeatureName = "cv_builder",
                        FeatureValue = "true",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = proPlan.Id,
                        FeatureName = "video_call",
                        FeatureValue = "true",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = proPlan.Id,
                        FeatureName = "cv_templates_premium",
                        FeatureValue = "true",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = proPlan.Id,
                        FeatureName = "priority_support",
                        FeatureValue = "false",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = proPlan.Id,
                        FeatureName = "cv_export_pdf",
                        FeatureValue = "true",
                        CreatedAt = DateTime.UtcNow
                    }
                });
            }

            // Enterprise plan features
            var enterprisePlan = plans.FirstOrDefault(p => p.Name == "Enterprise");
            if (enterprisePlan != null)
            {
                features.AddRange(new[]
                {
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = enterprisePlan.Id,
                        FeatureName = "max_applications",
                        FeatureValue = "unlimited",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = enterprisePlan.Id,
                        FeatureName = "cv_builder",
                        FeatureValue = "true",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = enterprisePlan.Id,
                        FeatureName = "video_call",
                        FeatureValue = "true",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = enterprisePlan.Id,
                        FeatureName = "cv_templates_premium",
                        FeatureValue = "true",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = enterprisePlan.Id,
                        FeatureName = "priority_support",
                        FeatureValue = "true",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = enterprisePlan.Id,
                        FeatureName = "cv_export_pdf",
                        FeatureValue = "true",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = enterprisePlan.Id,
                        FeatureName = "job_posting_boost",
                        FeatureValue = "true",
                        CreatedAt = DateTime.UtcNow
                    },
                    new SubscriptionFeature
                    {
                        SubscriptionPlanId = enterprisePlan.Id,
                        FeatureName = "analytics_advanced",
                        FeatureValue = "true",
                        CreatedAt = DateTime.UtcNow
                    }
                });
            }

            context.SubscriptionFeatures.AddRange(features);
            context.SaveChanges();

            Console.WriteLine($"Seeded {features.Count} subscription features across all plans.");
        }

        public static void SeedAll(ApplicationDbContext context)
        {
            Console.WriteLine("Starting to seed payment data...");
            SeedSubscriptionPlans(context);
            Console.WriteLine("Payment data seeding completed.");
        }
    }
}
