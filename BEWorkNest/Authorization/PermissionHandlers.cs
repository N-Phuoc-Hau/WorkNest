using Microsoft.AspNetCore.Authorization;
using BEWorkNest.Models;
using BEWorkNest.Data;
using Microsoft.EntityFrameworkCore;

namespace BEWorkNest.Authorization
{
    // Base permission handler
    public abstract class BasePermissionHandler<T> : AuthorizationHandler<T> where T : IAuthorizationRequirement
    {
        protected readonly ApplicationDbContext _context;
        protected readonly IHttpContextAccessor _httpContextAccessor;

        public BasePermissionHandler(ApplicationDbContext context, IHttpContextAccessor httpContextAccessor)
        {
            _context = context;
            _httpContextAccessor = httpContextAccessor;
        }

        protected string? GetCurrentUserId()
        {
            return _httpContextAccessor.HttpContext?.User?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        }

        protected string? GetCurrentUserRole()
        {
            return _httpContextAccessor.HttpContext?.User?.FindFirst("role")?.Value;
        }
    }

    // Requirements
    public class IsOwnerRequirement : IAuthorizationRequirement { }
    public class IsRecruiterRequirement : IAuthorizationRequirement { }
    public class IsCandidateRequirement : IAuthorizationRequirement { }
    public class IsRecruiterJobPostRequirement : IAuthorizationRequirement { }
    public class IsRecruiterApplicationRequirement : IAuthorizationRequirement { }
    public class CanCandidateReviewRequirement : IAuthorizationRequirement { }
    public class CanRecruiterReviewRequirement : IAuthorizationRequirement { }

    // Handlers
    public class IsOwnerHandler : BasePermissionHandler<IsOwnerRequirement>
    {
        public IsOwnerHandler(ApplicationDbContext context, IHttpContextAccessor httpContextAccessor) 
            : base(context, httpContextAccessor) { }

        protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, IsOwnerRequirement requirement)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
            {
                context.Fail();
                return Task.CompletedTask;
            }

            // This handler needs to be implemented based on resource type
            context.Succeed(requirement);
            return Task.CompletedTask;
        }
    }

    public class IsRecruiterHandler : BasePermissionHandler<IsRecruiterRequirement>
    {
        public IsRecruiterHandler(ApplicationDbContext context, IHttpContextAccessor httpContextAccessor) 
            : base(context, httpContextAccessor) { }

        protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, IsRecruiterRequirement requirement)
        {
            var role = GetCurrentUserRole();
            if (role == "recruiter")
            {
                context.Succeed(requirement);
            }
            else
            {
                context.Fail();
            }
            return Task.CompletedTask;
        }
    }

    public class IsCandidateHandler : BasePermissionHandler<IsCandidateRequirement>
    {
        public IsCandidateHandler(ApplicationDbContext context, IHttpContextAccessor httpContextAccessor) 
            : base(context, httpContextAccessor) { }

        protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, IsCandidateRequirement requirement)
        {
            var role = GetCurrentUserRole();
            if (role == "candidate")
            {
                context.Succeed(requirement);
            }
            else
            {
                context.Fail();
            }
            return Task.CompletedTask;
        }
    }

    public class CanCandidateReviewHandler : BasePermissionHandler<CanCandidateReviewRequirement>
    {
        public CanCandidateReviewHandler(ApplicationDbContext context, IHttpContextAccessor httpContextAccessor) 
            : base(context, httpContextAccessor) { }

        protected override async Task HandleRequirementAsync(AuthorizationHandlerContext context, CanCandidateReviewRequirement requirement)
        {
            var userId = GetCurrentUserId();
            var role = GetCurrentUserRole();
            
            if (userId == null || role != "candidate")
            {
                context.Fail();
                return;
            }

            // Get company_id from request (this would need to be passed through context)
            // For now, we'll mark this as succeeded - actual implementation would check application status
            context.Succeed(requirement);
        }
    }

    public class CanRecruiterReviewHandler : BasePermissionHandler<CanRecruiterReviewRequirement>
    {
        public CanRecruiterReviewHandler(ApplicationDbContext context, IHttpContextAccessor httpContextAccessor) 
            : base(context, httpContextAccessor) { }

        protected override async Task HandleRequirementAsync(AuthorizationHandlerContext context, CanRecruiterReviewRequirement requirement)
        {
            var userId = GetCurrentUserId();
            var role = GetCurrentUserRole();
            
            if (userId == null || role != "recruiter")
            {
                context.Fail();
                return;
            }

            // Similar to candidate review - actual implementation would check application status
            context.Succeed(requirement);
        }
    }
}
