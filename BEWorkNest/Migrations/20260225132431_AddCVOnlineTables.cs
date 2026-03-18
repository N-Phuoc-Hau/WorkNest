using System;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BEWorkNest.Migrations
{
    /// <inheritdoc />
    public partial class AddCVOnlineTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "CVTemplates",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    Name = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Description = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    ThumbnailUrl = table.Column<string>(type: "longtext", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    PreviewUrl = table.Column<string>(type: "longtext", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Category = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    IsPremium = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    IsActive = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    UsageCount = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    LayoutConfig = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CVTemplates", x => x.Id);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "CVOnlineProfiles",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    UserId = table.Column<string>(type: "varchar(255)", nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Title = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    FullName = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Email = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Phone = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Address = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    City = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Country = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Website = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    LinkedIn = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    GitHub = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Portfolio = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    ProfilePhotoUrl = table.Column<string>(type: "longtext", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Summary = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    CurrentPosition = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    YearsOfExperience = table.Column<int>(type: "int", nullable: true),
                    TemplateId = table.Column<int>(type: "int", nullable: true),
                    Theme = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    PrimaryColor = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    SecondaryColor = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    IsPublic = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    PublicSlug = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    IsDefault = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ShowPhoto = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ShowContactInfo = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    LastPublishedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    ViewCount = table.Column<int>(type: "int", nullable: false),
                    DownloadCount = table.Column<int>(type: "int", nullable: false),
                    UserId1 = table.Column<string>(type: "varchar(255)", nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CVOnlineProfiles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CVOnlineProfiles_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CVOnlineProfiles_AspNetUsers_UserId1",
                        column: x => x.UserId1,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CVOnlineProfiles_CVTemplates_TemplateId",
                        column: x => x.TemplateId,
                        principalTable: "CVTemplates",
                        principalColumn: "Id");
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "CVCertifications",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    CVProfileId = table.Column<int>(type: "int", nullable: false),
                    Name = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    IssuingOrganization = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    IssueDate = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    ExpiryDate = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    CredentialId = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    CredentialUrl = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    DisplayOrder = table.Column<int>(type: "int", nullable: false),
                    CVProfileId1 = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CVCertifications", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CVCertifications_CVOnlineProfiles_CVProfileId",
                        column: x => x.CVProfileId,
                        principalTable: "CVOnlineProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CVCertifications_CVOnlineProfiles_CVProfileId1",
                        column: x => x.CVProfileId1,
                        principalTable: "CVOnlineProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "CVEducations",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    CVProfileId = table.Column<int>(type: "int", nullable: false),
                    Degree = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Institution = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Location = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    GPA = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    StartDate = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    EndDate = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    IsCurrentlyStudying = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Courses = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    DisplayOrder = table.Column<int>(type: "int", nullable: false),
                    CVProfileId1 = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CVEducations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CVEducations_CVOnlineProfiles_CVProfileId",
                        column: x => x.CVProfileId,
                        principalTable: "CVOnlineProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CVEducations_CVOnlineProfiles_CVProfileId1",
                        column: x => x.CVProfileId1,
                        principalTable: "CVOnlineProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "CVLanguages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    CVProfileId = table.Column<int>(type: "int", nullable: false),
                    Name = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    ProficiencyLevel = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    DisplayOrder = table.Column<int>(type: "int", nullable: false),
                    CVProfileId1 = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CVLanguages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CVLanguages_CVOnlineProfiles_CVProfileId",
                        column: x => x.CVProfileId,
                        principalTable: "CVOnlineProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CVLanguages_CVOnlineProfiles_CVProfileId1",
                        column: x => x.CVProfileId1,
                        principalTable: "CVOnlineProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "CVProjects",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    CVProfileId = table.Column<int>(type: "int", nullable: false),
                    Name = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Link = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    StartDate = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    EndDate = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    Description = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Technologies = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Achievements = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    DisplayOrder = table.Column<int>(type: "int", nullable: false),
                    CVProfileId1 = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CVProjects", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CVProjects_CVOnlineProfiles_CVProfileId",
                        column: x => x.CVProfileId,
                        principalTable: "CVOnlineProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CVProjects_CVOnlineProfiles_CVProfileId1",
                        column: x => x.CVProfileId1,
                        principalTable: "CVOnlineProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "CVReferences",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    CVProfileId = table.Column<int>(type: "int", nullable: false),
                    Name = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Position = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Company = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Email = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Phone = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    DisplayOrder = table.Column<int>(type: "int", nullable: false),
                    CVProfileId1 = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CVReferences", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CVReferences_CVOnlineProfiles_CVProfileId",
                        column: x => x.CVProfileId,
                        principalTable: "CVOnlineProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CVReferences_CVOnlineProfiles_CVProfileId1",
                        column: x => x.CVProfileId1,
                        principalTable: "CVOnlineProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "CVSkills",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    CVProfileId = table.Column<int>(type: "int", nullable: false),
                    Name = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Category = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    ProficiencyLevel = table.Column<int>(type: "int", nullable: true),
                    YearsOfExperience = table.Column<int>(type: "int", nullable: true),
                    DisplayOrder = table.Column<int>(type: "int", nullable: false),
                    CVProfileId1 = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CVSkills", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CVSkills_CVOnlineProfiles_CVProfileId",
                        column: x => x.CVProfileId,
                        principalTable: "CVOnlineProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CVSkills_CVOnlineProfiles_CVProfileId1",
                        column: x => x.CVProfileId1,
                        principalTable: "CVOnlineProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "CVWorkExperiences",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    CVProfileId = table.Column<int>(type: "int", nullable: false),
                    JobTitle = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Company = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Location = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    StartDate = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    EndDate = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    IsCurrentJob = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Achievements = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Technologies = table.Column<string>(type: "text", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    DisplayOrder = table.Column<int>(type: "int", nullable: false),
                    CVProfileId1 = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CVWorkExperiences", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CVWorkExperiences_CVOnlineProfiles_CVProfileId",
                        column: x => x.CVProfileId,
                        principalTable: "CVOnlineProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CVWorkExperiences_CVOnlineProfiles_CVProfileId1",
                        column: x => x.CVProfileId1,
                        principalTable: "CVOnlineProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_CVCertifications_CVProfileId",
                table: "CVCertifications",
                column: "CVProfileId");

            migrationBuilder.CreateIndex(
                name: "IX_CVCertifications_CVProfileId_DisplayOrder",
                table: "CVCertifications",
                columns: new[] { "CVProfileId", "DisplayOrder" });

            migrationBuilder.CreateIndex(
                name: "IX_CVCertifications_CVProfileId1",
                table: "CVCertifications",
                column: "CVProfileId1");

            migrationBuilder.CreateIndex(
                name: "IX_CVEducations_CVProfileId",
                table: "CVEducations",
                column: "CVProfileId");

            migrationBuilder.CreateIndex(
                name: "IX_CVEducations_CVProfileId_DisplayOrder",
                table: "CVEducations",
                columns: new[] { "CVProfileId", "DisplayOrder" });

            migrationBuilder.CreateIndex(
                name: "IX_CVEducations_CVProfileId1",
                table: "CVEducations",
                column: "CVProfileId1");

            migrationBuilder.CreateIndex(
                name: "IX_CVLanguages_CVProfileId",
                table: "CVLanguages",
                column: "CVProfileId");

            migrationBuilder.CreateIndex(
                name: "IX_CVLanguages_CVProfileId_DisplayOrder",
                table: "CVLanguages",
                columns: new[] { "CVProfileId", "DisplayOrder" });

            migrationBuilder.CreateIndex(
                name: "IX_CVLanguages_CVProfileId1",
                table: "CVLanguages",
                column: "CVProfileId1");

            migrationBuilder.CreateIndex(
                name: "IX_CVOnlineProfiles_IsPublic",
                table: "CVOnlineProfiles",
                column: "IsPublic");

            migrationBuilder.CreateIndex(
                name: "IX_CVOnlineProfiles_PublicSlug",
                table: "CVOnlineProfiles",
                column: "PublicSlug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CVOnlineProfiles_TemplateId",
                table: "CVOnlineProfiles",
                column: "TemplateId");

            migrationBuilder.CreateIndex(
                name: "IX_CVOnlineProfiles_UserId",
                table: "CVOnlineProfiles",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_CVOnlineProfiles_UserId_IsDefault",
                table: "CVOnlineProfiles",
                columns: new[] { "UserId", "IsDefault" });

            migrationBuilder.CreateIndex(
                name: "IX_CVOnlineProfiles_UserId1",
                table: "CVOnlineProfiles",
                column: "UserId1");

            migrationBuilder.CreateIndex(
                name: "IX_CVProjects_CVProfileId",
                table: "CVProjects",
                column: "CVProfileId");

            migrationBuilder.CreateIndex(
                name: "IX_CVProjects_CVProfileId_DisplayOrder",
                table: "CVProjects",
                columns: new[] { "CVProfileId", "DisplayOrder" });

            migrationBuilder.CreateIndex(
                name: "IX_CVProjects_CVProfileId1",
                table: "CVProjects",
                column: "CVProfileId1");

            migrationBuilder.CreateIndex(
                name: "IX_CVReferences_CVProfileId",
                table: "CVReferences",
                column: "CVProfileId");

            migrationBuilder.CreateIndex(
                name: "IX_CVReferences_CVProfileId_DisplayOrder",
                table: "CVReferences",
                columns: new[] { "CVProfileId", "DisplayOrder" });

            migrationBuilder.CreateIndex(
                name: "IX_CVReferences_CVProfileId1",
                table: "CVReferences",
                column: "CVProfileId1");

            migrationBuilder.CreateIndex(
                name: "IX_CVSkills_Category",
                table: "CVSkills",
                column: "Category");

            migrationBuilder.CreateIndex(
                name: "IX_CVSkills_CVProfileId",
                table: "CVSkills",
                column: "CVProfileId");

            migrationBuilder.CreateIndex(
                name: "IX_CVSkills_CVProfileId_DisplayOrder",
                table: "CVSkills",
                columns: new[] { "CVProfileId", "DisplayOrder" });

            migrationBuilder.CreateIndex(
                name: "IX_CVSkills_CVProfileId1",
                table: "CVSkills",
                column: "CVProfileId1");

            migrationBuilder.CreateIndex(
                name: "IX_CVTemplates_Category",
                table: "CVTemplates",
                column: "Category");

            migrationBuilder.CreateIndex(
                name: "IX_CVTemplates_Category_IsPremium_IsActive",
                table: "CVTemplates",
                columns: new[] { "Category", "IsPremium", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_CVTemplates_IsActive",
                table: "CVTemplates",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_CVTemplates_IsPremium",
                table: "CVTemplates",
                column: "IsPremium");

            migrationBuilder.CreateIndex(
                name: "IX_CVWorkExperiences_CVProfileId",
                table: "CVWorkExperiences",
                column: "CVProfileId");

            migrationBuilder.CreateIndex(
                name: "IX_CVWorkExperiences_CVProfileId_DisplayOrder",
                table: "CVWorkExperiences",
                columns: new[] { "CVProfileId", "DisplayOrder" });

            migrationBuilder.CreateIndex(
                name: "IX_CVWorkExperiences_CVProfileId1",
                table: "CVWorkExperiences",
                column: "CVProfileId1");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "CVCertifications");

            migrationBuilder.DropTable(
                name: "CVEducations");

            migrationBuilder.DropTable(
                name: "CVLanguages");

            migrationBuilder.DropTable(
                name: "CVProjects");

            migrationBuilder.DropTable(
                name: "CVReferences");

            migrationBuilder.DropTable(
                name: "CVSkills");

            migrationBuilder.DropTable(
                name: "CVWorkExperiences");

            migrationBuilder.DropTable(
                name: "CVOnlineProfiles");

            migrationBuilder.DropTable(
                name: "CVTemplates");
        }
    }
}
