using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BEWorkNest.Migrations
{
    /// <inheritdoc />
    public partial class FixCVOnlineShadowForeignKeys : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CVCertifications_CVOnlineProfiles_CVProfileId1",
                table: "CVCertifications");

            migrationBuilder.DropForeignKey(
                name: "FK_CVEducations_CVOnlineProfiles_CVProfileId1",
                table: "CVEducations");

            migrationBuilder.DropForeignKey(
                name: "FK_CVLanguages_CVOnlineProfiles_CVProfileId1",
                table: "CVLanguages");

            migrationBuilder.DropForeignKey(
                name: "FK_CVOnlineProfiles_AspNetUsers_UserId1",
                table: "CVOnlineProfiles");

            migrationBuilder.DropForeignKey(
                name: "FK_CVProjects_CVOnlineProfiles_CVProfileId1",
                table: "CVProjects");

            migrationBuilder.DropForeignKey(
                name: "FK_CVReferences_CVOnlineProfiles_CVProfileId1",
                table: "CVReferences");

            migrationBuilder.DropForeignKey(
                name: "FK_CVSkills_CVOnlineProfiles_CVProfileId1",
                table: "CVSkills");

            migrationBuilder.DropForeignKey(
                name: "FK_CVWorkExperiences_CVOnlineProfiles_CVProfileId1",
                table: "CVWorkExperiences");

            migrationBuilder.DropIndex(
                name: "IX_CVWorkExperiences_CVProfileId1",
                table: "CVWorkExperiences");

            migrationBuilder.DropIndex(
                name: "IX_CVSkills_CVProfileId1",
                table: "CVSkills");

            migrationBuilder.DropIndex(
                name: "IX_CVReferences_CVProfileId1",
                table: "CVReferences");

            migrationBuilder.DropIndex(
                name: "IX_CVProjects_CVProfileId1",
                table: "CVProjects");

            migrationBuilder.DropIndex(
                name: "IX_CVOnlineProfiles_UserId1",
                table: "CVOnlineProfiles");

            migrationBuilder.DropIndex(
                name: "IX_CVLanguages_CVProfileId1",
                table: "CVLanguages");

            migrationBuilder.DropIndex(
                name: "IX_CVEducations_CVProfileId1",
                table: "CVEducations");

            migrationBuilder.DropIndex(
                name: "IX_CVCertifications_CVProfileId1",
                table: "CVCertifications");

            migrationBuilder.DropColumn(
                name: "CVProfileId1",
                table: "CVWorkExperiences");

            migrationBuilder.DropColumn(
                name: "CVProfileId1",
                table: "CVSkills");

            migrationBuilder.DropColumn(
                name: "CVProfileId1",
                table: "CVReferences");

            migrationBuilder.DropColumn(
                name: "CVProfileId1",
                table: "CVProjects");

            migrationBuilder.DropColumn(
                name: "UserId1",
                table: "CVOnlineProfiles");

            migrationBuilder.DropColumn(
                name: "CVProfileId1",
                table: "CVLanguages");

            migrationBuilder.DropColumn(
                name: "CVProfileId1",
                table: "CVEducations");

            migrationBuilder.DropColumn(
                name: "CVProfileId1",
                table: "CVCertifications");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CVProfileId1",
                table: "CVWorkExperiences",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "CVProfileId1",
                table: "CVSkills",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "CVProfileId1",
                table: "CVReferences",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "CVProfileId1",
                table: "CVProjects",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "UserId1",
                table: "CVOnlineProfiles",
                type: "varchar(255)",
                nullable: false,
                defaultValue: "")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<int>(
                name: "CVProfileId1",
                table: "CVLanguages",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "CVProfileId1",
                table: "CVEducations",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "CVProfileId1",
                table: "CVCertifications",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_CVWorkExperiences_CVProfileId1",
                table: "CVWorkExperiences",
                column: "CVProfileId1");

            migrationBuilder.CreateIndex(
                name: "IX_CVSkills_CVProfileId1",
                table: "CVSkills",
                column: "CVProfileId1");

            migrationBuilder.CreateIndex(
                name: "IX_CVReferences_CVProfileId1",
                table: "CVReferences",
                column: "CVProfileId1");

            migrationBuilder.CreateIndex(
                name: "IX_CVProjects_CVProfileId1",
                table: "CVProjects",
                column: "CVProfileId1");

            migrationBuilder.CreateIndex(
                name: "IX_CVOnlineProfiles_UserId1",
                table: "CVOnlineProfiles",
                column: "UserId1");

            migrationBuilder.CreateIndex(
                name: "IX_CVLanguages_CVProfileId1",
                table: "CVLanguages",
                column: "CVProfileId1");

            migrationBuilder.CreateIndex(
                name: "IX_CVEducations_CVProfileId1",
                table: "CVEducations",
                column: "CVProfileId1");

            migrationBuilder.CreateIndex(
                name: "IX_CVCertifications_CVProfileId1",
                table: "CVCertifications",
                column: "CVProfileId1");

            migrationBuilder.AddForeignKey(
                name: "FK_CVCertifications_CVOnlineProfiles_CVProfileId1",
                table: "CVCertifications",
                column: "CVProfileId1",
                principalTable: "CVOnlineProfiles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_CVEducations_CVOnlineProfiles_CVProfileId1",
                table: "CVEducations",
                column: "CVProfileId1",
                principalTable: "CVOnlineProfiles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_CVLanguages_CVOnlineProfiles_CVProfileId1",
                table: "CVLanguages",
                column: "CVProfileId1",
                principalTable: "CVOnlineProfiles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_CVOnlineProfiles_AspNetUsers_UserId1",
                table: "CVOnlineProfiles",
                column: "UserId1",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_CVProjects_CVOnlineProfiles_CVProfileId1",
                table: "CVProjects",
                column: "CVProfileId1",
                principalTable: "CVOnlineProfiles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_CVReferences_CVOnlineProfiles_CVProfileId1",
                table: "CVReferences",
                column: "CVProfileId1",
                principalTable: "CVOnlineProfiles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_CVSkills_CVOnlineProfiles_CVProfileId1",
                table: "CVSkills",
                column: "CVProfileId1",
                principalTable: "CVOnlineProfiles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_CVWorkExperiences_CVOnlineProfiles_CVProfileId1",
                table: "CVWorkExperiences",
                column: "CVProfileId1",
                principalTable: "CVOnlineProfiles",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
